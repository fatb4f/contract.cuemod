package transaction

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sync"
)

type JSONLJournalStore struct {
	Root string
	mu   sync.Mutex
}

func (s *JSONLJournalStore) Append(_ context.Context, entry JournalEntry) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	path := s.path(entry.TransactionID)
	entries, err := readJournal(path)
	if err != nil {
		return err
	}
	if entry.Seq != len(entries) {
		return fmt.Errorf("journal sequence %d is not contiguous after %d entries", entry.Seq, len(entries))
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return fmt.Errorf("create journal directory: %w", err)
	}
	file, err := os.OpenFile(path, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o600)
	if err != nil {
		return fmt.Errorf("open journal: %w", err)
	}
	encoder := json.NewEncoder(file)
	if err := encoder.Encode(entry); err != nil {
		_ = file.Close()
		return fmt.Errorf("append journal: %w", err)
	}
	if err := file.Sync(); err != nil {
		_ = file.Close()
		return fmt.Errorf("sync journal: %w", err)
	}
	if err := file.Close(); err != nil {
		return fmt.Errorf("close journal: %w", err)
	}
	return nil
}

func (s *JSONLJournalStore) Entries(_ context.Context, id string) ([]JournalEntry, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return readJournal(s.path(id))
}

func (s *JSONLJournalStore) path(id string) string {
	return filepath.Join(s.Root, id, "journal.jsonl")
}

func readJournal(path string) ([]JournalEntry, error) {
	file, err := os.Open(path)
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("open journal: %w", err)
	}
	defer file.Close()

	var entries []JournalEntry
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		var entry JournalEntry
		if err := json.Unmarshal(scanner.Bytes(), &entry); err != nil {
			return nil, fmt.Errorf("decode journal entry: %w", err)
		}
		entries = append(entries, entry)
	}
	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("read journal: %w", err)
	}
	return entries, nil
}

type DirectoryEvidenceEmitter struct {
	Root           string
	SealPostflight bool
}

type StoredEvidence struct {
	TransactionID string           `json:"transaction_id"`
	Command       string           `json:"command"`
	State         State            `json:"state"`
	FailureClass  FailureClass     `json:"failure_class,omitempty"`
	Preflight     Preflight        `json:"preflight"`
	Postflight    *RepositoryState `json:"postflight,omitempty"`
	Snapshot      Snapshot         `json:"snapshot"`
	Journal       []JournalEntry   `json:"journal"`
	Recovery      *RecoveryReport  `json:"recovery,omitempty"`
}

type RepositoryState struct {
	IndexTreeOID  string            `json:"indexTreeOID"`
	WorktreePatch string            `json:"worktreePatch"`
	Untracked     []string          `json:"untracked"`
	Refs          map[string]string `json:"refs"`
}

func (e DirectoryEvidenceEmitter) Emit(
	ctx context.Context,
	tx View,
	recovery *RecoveryReport,
	failure FailureClass,
) ([]EvidenceRef, error) {
	if e.Root == "" {
		return nil, errors.New("evidence root is required")
	}
	dir := filepath.Join(e.Root, tx.ID())
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return nil, fmt.Errorf("create evidence directory: %w", err)
	}
	payload := StoredEvidence{
		TransactionID: tx.ID(), Command: tx.Command(), State: tx.State(),
		FailureClass: failure, Preflight: tx.Preflight(), Snapshot: tx.Snapshot(),
		Journal: tx.Journal(), Recovery: recovery,
	}
	if e.SealPostflight && tx.State() == StateCommitted && failure == "" {
		postflight, err := captureRepositoryState(ctx, tx)
		if err != nil {
			return nil, fmt.Errorf("capture postflight state: %w", err)
		}
		payload.Postflight = &postflight
	}
	encoded, err := json.MarshalIndent(payload, "", "  ")
	if err != nil {
		return nil, fmt.Errorf("encode evidence: %w", err)
	}

	kinds := evidenceKinds(tx, recovery, failure)
	refs := make([]EvidenceRef, 0, len(kinds))
	for _, kind := range kinds {
		path := filepath.Join(dir, kind+".json")
		if err := writeImmutable(path, append(encoded, '\n')); err != nil {
			return nil, fmt.Errorf("write %s evidence: %w", kind, err)
		}
		absolute, err := filepath.Abs(path)
		if err != nil {
			return nil, fmt.Errorf("resolve evidence path: %w", err)
		}
		refs = append(refs, EvidenceRef{
			TransactionID: tx.ID(), Kind: kind,
			URI: "file://" + filepath.ToSlash(absolute), Immutable: true,
		})
	}
	return refs, nil
}

func captureRepositoryState(ctx context.Context, tx View) (RepositoryState, error) {
	root := tx.Preflight().RepoRoot
	indexTree, err := git(ctx, root, "write-tree")
	if err != nil {
		return RepositoryState{}, err
	}
	worktree, err := git(ctx, root, "diff", "HEAD", "--binary")
	if err != nil {
		return RepositoryState{}, err
	}
	untracked, err := git(ctx, root, "ls-files", "--others", "--exclude-standard")
	if err != nil {
		return RepositoryState{}, err
	}
	refs := map[string]string{}
	for ref := range tx.Snapshot().Refs {
		oid, refErr := git(ctx, root, "rev-parse", "--verify", ref)
		if refErr == nil {
			refs[ref] = oid
		}
	}
	if tx.Command() == "stack.finalizePatch" {
		var request FinalizePatchRequest
		if json.Unmarshal([]byte(tx.Snapshot().Operation), &request) == nil {
			ref := "refs/stack/patches/" + request.PatchID
			oid, refErr := git(ctx, root, "rev-parse", "--verify", ref)
			if refErr == nil {
				refs[ref] = oid
			}
		}
	}
	return RepositoryState{
		IndexTreeOID: indexTree, WorktreePatch: worktree,
		Untracked: lines(untracked), Refs: refs,
	}, nil
}

func writeImmutable(path string, content []byte) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return err
	}
	temp, err := os.CreateTemp(filepath.Dir(path), ".evidence-*")
	if err != nil {
		return err
	}
	tempPath := temp.Name()
	defer os.Remove(tempPath)
	if err := temp.Chmod(0o400); err != nil {
		_ = temp.Close()
		return err
	}
	if _, err := temp.Write(content); err != nil {
		_ = temp.Close()
		return err
	}
	if err := temp.Sync(); err != nil {
		_ = temp.Close()
		return err
	}
	if err := temp.Close(); err != nil {
		return err
	}
	return os.Rename(tempPath, path)
}

func LoadStoredEvidence(root, transactionID string) (StoredEvidence, error) {
	if !transactionIDPattern.MatchString(transactionID) {
		return StoredEvidence{}, fmt.Errorf("invalid transaction ID %q", transactionID)
	}
	path := filepath.Join(root, transactionID, "transaction.json")
	content, err := os.ReadFile(path)
	if err != nil {
		return StoredEvidence{}, fmt.Errorf("read transaction evidence: %w", err)
	}
	var evidence StoredEvidence
	if err := json.Unmarshal(content, &evidence); err != nil {
		return StoredEvidence{}, fmt.Errorf("decode transaction evidence: %w", err)
	}
	if evidence.TransactionID != transactionID || evidence.Snapshot.TransactionID != transactionID {
		return StoredEvidence{}, errors.New("transaction evidence identity mismatch")
	}
	return evidence, nil
}
