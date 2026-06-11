package transaction

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"time"
)

type RollbackRequest struct {
	ActivePatchID       string        `json:"activePatchID"`
	TargetTransactionID string        `json:"targetTransactionID"`
	RollbackClass       RollbackClass `json:"rollbackClass"`
}

type RollbackResponse struct {
	TransactionID       string          `json:"transactionID"`
	Command             string          `json:"command"`
	TargetTransactionID string          `json:"targetTransactionID"`
	State               State           `json:"state"`
	OK                  bool            `json:"ok"`
	RollbackClass       RollbackClass   `json:"rollbackClass"`
	Recovery            *RecoveryReport `json:"recovery"`
	Evidence            []EvidenceRef   `json:"evidence"`
}

type RollbackService struct {
	RepoRoot     string
	ArtifactRoot string
	Observer     PreflightObserver
	Now          Clock
	NewID        func() (string, error)
}

func (s RollbackService) Run(ctx context.Context, request RollbackRequest) (*RollbackResponse, error) {
	if strings.TrimSpace(request.ActivePatchID) == "" {
		return nil, errors.New("activePatchID is required")
	}
	if request.RollbackClass == RollbackNone || request.RollbackClass == RollbackManualRequired {
		return nil, fmt.Errorf("rollbackClass %q is not an executable rollback class", request.RollbackClass)
	}
	target, err := LoadStoredEvidence(s.ArtifactRoot, request.TargetTransactionID)
	if err != nil {
		return nil, err
	}
	if target.State != StateCommitted {
		return nil, fmt.Errorf("target transaction state %q is not committed", target.State)
	}
	if filepath.Clean(target.Preflight.RepoRoot) != filepath.Clean(s.RepoRoot) {
		return nil, errors.New("target transaction belongs to a different repository")
	}
	declared := declaredRollbackClass(target.Journal)
	if declared == RollbackNone {
		return nil, errors.New("target evidence does not declare a rollback class")
	}
	if declared != request.RollbackClass {
		return nil, fmt.Errorf("requested rollback class %q does not match evidence class %q", request.RollbackClass, declared)
	}

	id, err := s.newID()
	if err != nil {
		return nil, err
	}
	now := s.clock()
	journal := &JSONLJournalStore{Root: s.ArtifactRoot}
	entries := []JournalEntry{
		{
			TransactionID: id, Seq: 0, Phase: PhasePreflight, Action: "load-target",
			Target: target.TransactionID, After: "verified", RollbackClass: declared, Timestamp: now().UTC(),
		},
		{
			TransactionID: id, Seq: 1, Phase: PhaseRollback, Action: "start",
			Target: target.TransactionID, After: "started", RollbackClass: declared, Timestamp: now().UTC(),
		},
	}
	for _, entry := range entries {
		if err := journal.Append(ctx, entry); err != nil {
			return nil, err
		}
	}

	recovery, rollbackErr := s.restore(ctx, target, request)
	finalState := recovery.State
	finish := JournalEntry{
		TransactionID: id, Seq: 2, Phase: PhaseRollback, Action: "finish",
		Target: target.TransactionID, Before: "started", After: string(finalState),
		RollbackClass: declared, Timestamp: now().UTC(),
	}
	if err := journal.Append(ctx, finish); err != nil {
		return nil, errors.Join(rollbackErr, err)
	}
	entries = append(entries, finish)

	response := &RollbackResponse{
		TransactionID: id, Command: "stack.rollback", TargetTransactionID: target.TransactionID,
		State: finalState, OK: finalState == StateRolledBack, RollbackClass: declared, Recovery: recovery,
	}
	evidence, evidenceErr := s.emitEvidence(response, target, entries)
	response.Evidence = evidence
	recovery.Evidence = append(recovery.Evidence, evidence...)
	return response, errors.Join(rollbackErr, evidenceErr)
}

func (s RollbackService) restore(
	ctx context.Context,
	target StoredEvidence,
	request RollbackRequest,
) (*RecoveryReport, error) {
	observer := s.Observer
	if observer == nil {
		observer = GitObserver{StackRefPrefixes: []string{"refs/heads", "refs/stack"}}
	}
	current, err := observer.Observe(ctx, LocalRepository(s.RepoRoot))
	if err != nil {
		return failedRecovery("observe rollback preflight", err)
	}
	if err := current.Validate(); err != nil {
		return failedRecovery("validate rollback preflight", err)
	}
	if current.ConflictStatePresent {
		return manualRecovery("rollback refused while a conflict operation is active"), nil
	}

	view := storedView{evidence: target}
	failure := ClassifiedFailure{RollbackClass: request.RollbackClass}
	switch request.RollbackClass {
	case RollbackIndexOnly:
		if target.Command != "stack.stage" {
			return manualRecovery("index rollback target was not created by stack.stage"), nil
		}
		var operation StageRequest
		if err := json.Unmarshal([]byte(target.Snapshot.Operation), &operation); err != nil {
			return manualRecovery("stage operation snapshot is unreadable"), nil
		}
		if operation.ActivePatchID != request.ActivePatchID {
			return manualRecovery("active patch does not match the target stage transaction"), nil
		}
		if target.Postflight == nil {
			return manualRecovery("target transaction does not contain a postflight state fingerprint"), nil
		}
		currentTree, err := git(ctx, s.RepoRoot, "write-tree")
		if err != nil {
			return failedRecovery("inspect current index", err)
		}
		if currentTree != target.Postflight.IndexTreeOID {
			return manualRecovery("index changed after the target stage transaction"), nil
		}
		worktree, err := git(ctx, s.RepoRoot, "diff", "HEAD", "--binary")
		if err != nil {
			return failedRecovery("inspect current worktree", err)
		}
		untracked, err := git(ctx, s.RepoRoot, "ls-files", "--others", "--exclude-standard")
		if err != nil {
			return failedRecovery("inspect current untracked files", err)
		}
		if worktree != target.Postflight.WorktreePatch ||
			!slices.Equal(lines(untracked), target.Postflight.Untracked) {
			return manualRecovery("worktree or untracked files changed after the target stage transaction"), nil
		}
		changed, err := StagedPaths(ctx, LocalRepository(s.RepoRoot), target.Snapshot.IndexTreeOID)
		if err != nil {
			return failedRecovery("inspect current index", err)
		}
		for _, path := range changed {
			if !slices.Contains(operation.Paths, filepath.ToSlash(path)) {
				return manualRecovery("index changed outside the target stage transaction"), nil
			}
		}
		recovery, err := (IndexSnapshotRollback{}).Restore(ctx, view, failure)
		if err != nil {
			return recovery, err
		}
		tree, verifyErr := git(ctx, s.RepoRoot, "write-tree")
		if verifyErr != nil || tree != target.Snapshot.IndexTreeOID {
			return failedRecovery("verify restored index", errors.Join(verifyErr, errors.New("index tree mismatch")))
		}
		return recovery, nil
	case RollbackRefOnly:
		if target.Command != "stack.finalizePatch" {
			return manualRecovery("ref rollback target was not created by stack.finalizePatch"), nil
		}
		var operation FinalizePatchRequest
		if err := json.Unmarshal([]byte(target.Snapshot.Operation), &operation); err != nil {
			return manualRecovery("finalize operation snapshot is unreadable"), nil
		}
		if operation.PatchID != request.ActivePatchID {
			return manualRecovery("active patch does not match the target finalize transaction"), nil
		}
		if err := validateFinalizeRollbackTarget(ctx, s.RepoRoot, target); err != nil {
			return manualRecovery(err.Error()), nil
		}
		recovery, err := (FinalizePatchRollback{}).Restore(ctx, view, failure)
		if err != nil {
			return recovery, err
		}
		if err := validateFinalizeRestoredState(ctx, s.RepoRoot, target); err != nil {
			return failedRecovery("verify restored finalize state", err)
		}
		return recovery, nil
	default:
		return manualRecovery(fmt.Sprintf(
			"rollback class %q requires an adapter not recorded by current stack operations",
			request.RollbackClass,
		)), nil
	}
}

func validateFinalizeRollbackTarget(ctx context.Context, root string, target StoredEvidence) error {
	var request FinalizePatchRequest
	if err := json.Unmarshal([]byte(target.Snapshot.Operation), &request); err != nil {
		return errors.New("finalize operation snapshot is unreadable")
	}
	stackRef := "refs/stack/patches/" + request.PatchID
	metadataPath := filepath.Join(root, ".git", "git-mcp-patches", request.PatchID+".json")
	content, err := os.ReadFile(metadataPath)
	if err != nil {
		return errors.New("finalized patch metadata is no longer present")
	}
	var metadata PatchMetadata
	if json.Unmarshal(content, &metadata) != nil {
		return errors.New("finalized patch metadata is unreadable")
	}
	current, err := git(ctx, root, "rev-parse", "--verify", stackRef)
	if err != nil || current != metadata.CommitOID || metadata.StackRef != stackRef {
		return errors.New("stack ref or metadata changed after the target transaction")
	}
	return nil
}

func validateFinalizeRestoredState(ctx context.Context, root string, target StoredEvidence) error {
	var request FinalizePatchRequest
	if err := json.Unmarshal([]byte(target.Snapshot.Operation), &request); err != nil {
		return err
	}
	stackRef := "refs/stack/patches/" + request.PatchID
	current, err := git(ctx, root, "rev-parse", "--verify", stackRef)
	old, existed := target.Snapshot.Refs[stackRef]
	if existed {
		if err != nil || current != old {
			return errors.New("previous stack ref was not restored")
		}
	} else if err == nil {
		return errors.New("new stack ref was not removed")
	}
	for path, content := range target.Snapshot.ArtifactState {
		actual, readErr := os.ReadFile(path)
		if content == nil {
			if !errors.Is(readErr, os.ErrNotExist) {
				return errors.New("new adapter artifact was not removed")
			}
			continue
		}
		if readErr != nil || string(actual) != *content {
			return errors.New("previous adapter artifact was not restored")
		}
	}
	return nil
}

func (s RollbackService) emitEvidence(
	response *RollbackResponse,
	target StoredEvidence,
	journal []JournalEntry,
) ([]EvidenceRef, error) {
	dir := filepath.Join(s.ArtifactRoot, response.TransactionID)
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return nil, err
	}
	payload := struct {
		*RollbackResponse
		TargetEvidence StoredEvidence `json:"targetEvidence"`
		Journal        []JournalEntry `json:"journal"`
	}{RollbackResponse: response, TargetEvidence: target, Journal: journal}
	encoded, err := json.MarshalIndent(payload, "", "  ")
	if err != nil {
		return nil, err
	}
	var refs []EvidenceRef
	for _, kind := range []string{"transaction", "rollback", "recovery"} {
		path := filepath.Join(dir, kind+".json")
		if err := writeImmutable(path, append(encoded, '\n')); err != nil {
			return nil, err
		}
		absolute, err := filepath.Abs(path)
		if err != nil {
			return nil, err
		}
		refs = append(refs, EvidenceRef{
			TransactionID: response.TransactionID, Kind: kind,
			URI: "file://" + filepath.ToSlash(absolute), Immutable: true,
		})
	}
	return refs, nil
}

func declaredRollbackClass(journal []JournalEntry) RollbackClass {
	for index := len(journal) - 1; index >= 0; index-- {
		if journal[index].RollbackClass != RollbackNone {
			return journal[index].RollbackClass
		}
	}
	return RollbackNone
}

func (s RollbackService) clock() Clock {
	if s.Now != nil {
		return s.Now
	}
	return time.Now
}

func (s RollbackService) newID() (string, error) {
	if s.NewID != nil {
		return s.NewID()
	}
	return transactionID()
}

type storedView struct {
	evidence StoredEvidence
}

func (v storedView) ID() string           { return v.evidence.TransactionID }
func (v storedView) State() State         { return v.evidence.State }
func (v storedView) Command() string      { return v.evidence.Command }
func (v storedView) Preflight() Preflight { return v.evidence.Preflight }
func (v storedView) Snapshot() Snapshot   { return v.evidence.Snapshot }
func (v storedView) Journal() []JournalEntry {
	return append([]JournalEntry(nil), v.evidence.Journal...)
}
