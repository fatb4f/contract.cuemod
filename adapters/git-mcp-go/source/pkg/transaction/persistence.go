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
	Root string
}

func (e DirectoryEvidenceEmitter) Emit(
	_ context.Context,
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
	payload := struct {
		TransactionID string          `json:"transaction_id"`
		Command       string          `json:"command"`
		State         State           `json:"state"`
		FailureClass  FailureClass    `json:"failure_class,omitempty"`
		Preflight     Preflight       `json:"preflight"`
		Snapshot      Snapshot        `json:"snapshot"`
		Journal       []JournalEntry  `json:"journal"`
		Recovery      *RecoveryReport `json:"recovery,omitempty"`
	}{
		TransactionID: tx.ID(), Command: tx.Command(), State: tx.State(),
		FailureClass: failure, Preflight: tx.Preflight(), Snapshot: tx.Snapshot(),
		Journal: tx.Journal(), Recovery: recovery,
	}
	encoded, err := json.MarshalIndent(payload, "", "  ")
	if err != nil {
		return nil, fmt.Errorf("encode evidence: %w", err)
	}

	kinds := evidenceKinds(tx, recovery, failure)
	refs := make([]EvidenceRef, 0, len(kinds))
	for _, kind := range kinds {
		path := filepath.Join(dir, kind+".json")
		if err := os.WriteFile(path, append(encoded, '\n'), 0o400); err != nil {
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
