package transaction

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"sync"
)

type LocalRepository string

func (r LocalRepository) Root() string { return string(r) }

type GuardedMutationAdapter struct{}

func (GuardedMutationAdapter) Apply(ctx context.Context, mutation Mutation, repo Repository) error {
	return mutation.Apply(ctx, repo)
}

type GitObserver struct {
	StackRefPrefixes []string
}

func (o GitObserver) Observe(ctx context.Context, repo Repository) (Preflight, error) {
	root, err := git(ctx, repo.Root(), "rev-parse", "--show-toplevel")
	if err != nil {
		return Preflight{}, err
	}
	head, err := git(ctx, repo.Root(), "rev-parse", "HEAD")
	if err != nil {
		return Preflight{}, err
	}
	headRef, _ := git(ctx, repo.Root(), "symbolic-ref", "-q", "HEAD")
	_, indexErr := git(ctx, repo.Root(), "diff", "--cached", "--quiet")
	_, worktreeErr := git(ctx, repo.Root(), "diff", "--quiet")
	untracked, err := git(ctx, repo.Root(), "ls-files", "--others", "--exclude-standard")
	if err != nil {
		return Preflight{}, err
	}
	refs := map[string]string{}
	for _, prefix := range o.StackRefPrefixes {
		output, refErr := git(ctx, repo.Root(), "for-each-ref", "--format=%(refname) %(objectname)", prefix)
		if refErr != nil {
			return Preflight{}, refErr
		}
		for _, line := range lines(output) {
			name, oid, ok := strings.Cut(line, " ")
			if ok {
				refs[name] = oid
			}
		}
	}
	conflict := false
	gitDir, err := git(ctx, repo.Root(), "rev-parse", "--git-dir")
	if err != nil {
		return Preflight{}, err
	}
	if !filepath.IsAbs(gitDir) {
		gitDir = filepath.Join(strings.TrimSpace(root), gitDir)
	}
	for _, marker := range []string{"MERGE_HEAD", "CHERRY_PICK_HEAD", "REVERT_HEAD", "rebase-apply", "rebase-merge"} {
		if _, statErr := os.Stat(filepath.Join(gitDir, marker)); statErr == nil {
			conflict = true
			break
		}
	}
	return Preflight{
		RepoRoot: strings.TrimSpace(root), HeadOID: strings.TrimSpace(head),
		HeadRef: strings.TrimSpace(headRef), IndexReadable: indexErr == nil || exitCode(indexErr) == 1,
		WorktreeReadable: worktreeErr == nil || exitCode(worktreeErr) == 1,
		IndexDirty:       exitCode(indexErr) == 1, WorktreeDirty: exitCode(worktreeErr) == 1,
		Untracked: lines(untracked), ConflictStatePresent: conflict, RelevantRefs: refs,
		Guards: []Guard{{Name: "head-known", Pass: strings.TrimSpace(head) != ""}},
	}, nil
}

type GitSnapshotStore struct{}

func (GitSnapshotStore) Capture(
	ctx context.Context,
	id string,
	repo Repository,
	preflight Preflight,
	policy Policy,
) (Snapshot, error) {
	snapshot := Snapshot{
		TransactionID: id, Coverage: map[Surface]Coverage{}, HeadOID: preflight.HeadOID,
		HeadRef: preflight.HeadRef, Refs: cloneMap(preflight.RelevantRefs),
		Untracked: append([]string(nil), preflight.Untracked...),
	}
	required := func(surface Surface) bool {
		for _, candidate := range policy.RequiredSnapshots {
			if candidate == surface {
				return true
			}
		}
		return false
	}
	for _, surface := range []Surface{
		SurfaceHead, SurfaceRefs, SurfaceIndex, SurfaceWorktree, SurfaceUntracked,
		SurfaceConflictState, SurfaceAdapterArtifacts, SurfaceOperationInput,
	} {
		snapshot.Coverage[surface] = CoverageNotRequired
	}
	snapshot.Coverage[SurfaceHead] = CoverageComplete
	snapshot.Coverage[SurfaceRefs] = CoverageComplete
	if required(SurfaceIndex) {
		index, err := git(ctx, repo.Root(), "diff", "--cached", "--binary")
		if err != nil {
			return Snapshot{}, err
		}
		snapshot.IndexArtifact = index
		snapshot.Coverage[SurfaceIndex] = CoverageComplete
	}
	if required(SurfaceWorktree) {
		worktree, err := git(ctx, repo.Root(), "diff", "--binary")
		if err != nil {
			return Snapshot{}, err
		}
		snapshot.WorktreePatch = worktree
		snapshot.Coverage[SurfaceWorktree] = CoverageComplete
	}
	if required(SurfaceUntracked) {
		snapshot.Coverage[SurfaceUntracked] = CoverageComplete
	}
	if required(SurfaceConflictState) {
		snapshot.ConflictState = fmt.Sprintf("present=%t", preflight.ConflictStatePresent)
		snapshot.Coverage[SurfaceConflictState] = CoverageComplete
	}
	if required(SurfaceAdapterArtifacts) {
		snapshot.Artifacts = append([]string(nil), preflight.AdapterArtifacts...)
		snapshot.Coverage[SurfaceAdapterArtifacts] = CoverageComplete
	}
	if required(SurfaceOperationInput) {
		snapshot.Operation = "captured by transaction request"
		snapshot.Coverage[SurfaceOperationInput] = CoverageComplete
	}
	return snapshot, nil
}

type MemoryJournalStore struct {
	mu      sync.Mutex
	entries map[string][]JournalEntry
}

func NewMemoryJournalStore() *MemoryJournalStore {
	return &MemoryJournalStore{entries: map[string][]JournalEntry{}}
}

func (s *MemoryJournalStore) Append(_ context.Context, entry JournalEntry) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	current := s.entries[entry.TransactionID]
	if entry.Seq != len(current) {
		return fmt.Errorf("journal sequence %d is not contiguous after %d entries", entry.Seq, len(current))
	}
	s.entries[entry.TransactionID] = append(current, entry)
	return nil
}

func (s *MemoryJournalStore) Entries(_ context.Context, id string) ([]JournalEntry, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return append([]JournalEntry(nil), s.entries[id]...), nil
}

type RollbackHandler interface {
	Restore(context.Context, View, ClassifiedFailure) (*RecoveryReport, error)
}

type Dispatcher struct {
	Handlers map[RollbackClass]RollbackHandler
}

func (d Dispatcher) Rollback(ctx context.Context, tx View, failure ClassifiedFailure) (*RecoveryReport, error) {
	if failure.RollbackClass == RollbackManualRequired {
		return manualRecovery("automatic rollback is not allowed by transaction policy"), nil
	}
	handler := d.Handlers[failure.RollbackClass]
	if handler == nil {
		return manualRecovery(fmt.Sprintf("rollback class %q is unsupported", failure.RollbackClass)), nil
	}
	return handler.Restore(ctx, tx, failure)
}

func (d Dispatcher) ValidateReflogOnly(class RollbackClass) error {
	if class != RollbackRefOnly {
		return fmt.Errorf("reflog-only rollback is forbidden for %q", class)
	}
	return nil
}

func manualRecovery(note string) *RecoveryReport {
	return &RecoveryReport{
		State: StateRollbackPartial, Recovered: false, ManualRequired: true,
		Notes: []string{note},
	}
}

type RefSnapshotRollback struct {
	RestoreRef func(context.Context, string, string, string) error
}

func (r RefSnapshotRollback) Restore(
	ctx context.Context,
	tx View,
	failure ClassifiedFailure,
) (*RecoveryReport, error) {
	if failure.RollbackClass != RollbackRefOnly {
		return manualRecovery("ref snapshot rollback only supports ref_only recovery"), nil
	}
	if r.RestoreRef == nil {
		return manualRecovery("ref restoration primitive is unavailable"), nil
	}
	snapshot := tx.Snapshot()
	if snapshot.HeadRef != "" {
		if err := r.RestoreRef(ctx, tx.Preflight().RepoRoot, snapshot.HeadRef, snapshot.HeadOID); err != nil {
			return &RecoveryReport{
				State: StateRollbackFailed, ManualRequired: true,
				Notes: []string{fmt.Sprintf("restore %s: %v", snapshot.HeadRef, err)},
			}, err
		}
	}
	for ref, oid := range snapshot.Refs {
		if ref == snapshot.HeadRef {
			continue
		}
		if err := r.RestoreRef(ctx, tx.Preflight().RepoRoot, ref, oid); err != nil {
			return &RecoveryReport{
				State: StateRollbackFailed, ManualRequired: true,
				Notes: []string{fmt.Sprintf("restore %s: %v", ref, err)},
			}, err
		}
	}
	return &RecoveryReport{State: StateRolledBack, Recovered: true}, nil
}

type URIEmitter struct{}

func (URIEmitter) Emit(
	_ context.Context,
	tx View,
	recovery *RecoveryReport,
	failure FailureClass,
) ([]EvidenceRef, error) {
	kinds := evidenceKinds(tx, recovery, failure)
	refs := make([]EvidenceRef, 0, len(kinds))
	for _, kind := range kinds {
		refs = append(refs, EvidenceRef{
			TransactionID: tx.ID(), Kind: kind,
			URI: fmt.Sprintf("tx://%s/%s", tx.ID(), kind), Immutable: true,
		})
	}
	return refs, nil
}

func evidenceKinds(tx View, recovery *RecoveryReport, failure FailureClass) []string {
	kinds := []string{"transaction"}
	if tx.Snapshot().TransactionID != "" {
		kinds = append(kinds, "snapshot")
	}
	journal := tx.Journal()
	if len(journal) > 0 {
		kinds = append(kinds, "journal")
	}
	for _, entry := range journal {
		if entry.Phase == PhasePostflight {
			kinds = append(kinds, "postflight")
			break
		}
	}
	if recovery != nil {
		kinds = append(kinds, "rollback")
	}
	if failure != "" {
		kinds = append(kinds, "diagnostic")
	}
	return kinds
}

type NoopMutation struct{}

func (NoopMutation) Name() string                            { return "noop" }
func (NoopMutation) AffectedSurfaces() []Surface             { return []Surface{SurfaceAdapterArtifacts} }
func (NoopMutation) Apply(context.Context, Repository) error { return nil }

type NoopValidator struct{}

func (NoopValidator) Name() string { return "noop-validator" }
func (NoopValidator) Validate(context.Context, Repository, View) error {
	return nil
}

func git(ctx context.Context, root string, args ...string) (string, error) {
	command := exec.CommandContext(ctx, "git", append([]string{"-C", root}, args...)...)
	output, err := command.CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("git %s: %w: %s", strings.Join(args, " "), err, strings.TrimSpace(string(output)))
	}
	return strings.TrimSpace(string(output)), nil
}

func exitCode(err error) int {
	var exitErr *exec.ExitError
	if errors.As(err, &exitErr) {
		return exitErr.ExitCode()
	}
	if err == nil {
		return 0
	}
	return -1
}

func lines(value string) []string {
	if strings.TrimSpace(value) == "" {
		return nil
	}
	result := strings.Split(strings.TrimSpace(value), "\n")
	sort.Strings(result)
	return result
}

func cloneMap(values map[string]string) map[string]string {
	result := make(map[string]string, len(values))
	for key, value := range values {
		result[key] = value
	}
	return result
}
