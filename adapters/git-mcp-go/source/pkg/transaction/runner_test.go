package transaction

import (
	"context"
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

type observerFunc func(context.Context, Repository) (Preflight, error)

func (f observerFunc) Observe(ctx context.Context, repo Repository) (Preflight, error) {
	return f(ctx, repo)
}

type snapshotFunc func(context.Context, string, Repository, Preflight, Policy) (Snapshot, error)

func (f snapshotFunc) Capture(
	ctx context.Context,
	id string,
	repo Repository,
	preflight Preflight,
	policy Policy,
) (Snapshot, error) {
	return f(ctx, id, repo, preflight, policy)
}

type mutationFunc struct {
	name     string
	surfaces []Surface
	apply    func(context.Context, Repository) error
}

func (m mutationFunc) Name() string                { return m.name }
func (m mutationFunc) AffectedSurfaces() []Surface { return m.surfaces }
func (m mutationFunc) Apply(ctx context.Context, repo Repository) error {
	return m.apply(ctx, repo)
}

type validatorFunc func(context.Context, Repository, View) error

func (validatorFunc) Name() string { return "test-validator" }
func (f validatorFunc) Validate(ctx context.Context, repo Repository, tx View) error {
	return f(ctx, repo, tx)
}

type rollbackFunc func(context.Context, View, ClassifiedFailure) (*RecoveryReport, error)

func (f rollbackFunc) Rollback(
	ctx context.Context,
	tx View,
	failure ClassifiedFailure,
) (*RecoveryReport, error) {
	return f(ctx, tx, failure)
}

type journalFunc struct {
	append  func(JournalEntry) error
	entries []JournalEntry
}

func (s *journalFunc) Append(_ context.Context, entry JournalEntry) error {
	if s.append != nil {
		if err := s.append(entry); err != nil {
			return err
		}
	}
	s.entries = append(s.entries, entry)
	return nil
}

func (s *journalFunc) Entries(context.Context, string) ([]JournalEntry, error) {
	return append([]JournalEntry(nil), s.entries...), nil
}

func TestValidTransitionRejectsLifecycleSkips(t *testing.T) {
	tests := []struct {
		from State
		to   State
	}{
		{StatePlanned, StateSnapshotCreated},
		{StatePreflighted, StateCommitted},
		{StateJournalOpened, StateCommitted},
		{StatePlanned, StateRollbackStarted},
		{StateCommitted, StateRollbackStarted},
	}
	for _, test := range tests {
		if ValidTransition(test.from, test.to) {
			t.Fatalf("transition %s -> %s unexpectedly allowed", test.from, test.to)
		}
	}
}

func TestRunnerNoopCompletesFullLifecycle(t *testing.T) {
	journal := NewMemoryJournalStore()
	runner := testRunner(journal)
	result, err := runner.Run(context.Background(), Request{
		Command: "stack.noop", Mutation: NoopMutation{}, Validator: NoopValidator{},
		Policy: Policy{
			RequiredSnapshots:      []Surface{SurfaceAdapterArtifacts},
			AllowedRollbackClasses: []RollbackClass{RollbackAdapterArtifact},
		},
	})
	if err != nil {
		t.Fatalf("Run() error = %v", err)
	}
	if !result.OK || result.State != StateCommitted {
		t.Fatalf("result = %#v", result)
	}
	wantPhases := []JournalPhase{
		PhasePreflight, PhaseSnapshot, PhaseJournal, PhaseMutation,
		PhaseMutation, PhasePostflight, PhasePostflight, PhaseCommit,
	}
	if len(result.Journal) != len(wantPhases) {
		t.Fatalf("journal entries = %d, want %d", len(result.Journal), len(wantPhases))
	}
	for i, entry := range result.Journal {
		if entry.Seq != i || entry.Phase != wantPhases[i] {
			t.Fatalf("journal[%d] = %#v", i, entry)
		}
	}
	assertEvidenceKinds(t, result.Evidence, "transaction", "snapshot", "journal", "postflight")
}

func TestRunnerFailureClasses(t *testing.T) {
	failure := errors.New("injected failure")
	tests := []struct {
		name      string
		configure func(*Runner, *journalFunc, *mutationFunc, *validatorFunc)
		wantClass FailureClass
		wantState State
	}{
		{
			name: "preflight",
			configure: func(r *Runner, _ *journalFunc, _ *mutationFunc, _ *validatorFunc) {
				r.observer = observerFunc(func(context.Context, Repository) (Preflight, error) {
					return Preflight{}, failure
				})
			},
			wantClass: FailurePreflight, wantState: StateAborted,
		},
		{
			name: "snapshot",
			configure: func(r *Runner, _ *journalFunc, _ *mutationFunc, _ *validatorFunc) {
				r.snapshots = snapshotFunc(func(context.Context, string, Repository, Preflight, Policy) (Snapshot, error) {
					return Snapshot{}, failure
				})
			},
			wantClass: FailureSnapshot, wantState: StateAborted,
		},
		{
			name: "journal-before-mutation",
			configure: func(_ *Runner, journal *journalFunc, _ *mutationFunc, _ *validatorFunc) {
				journal.append = func(JournalEntry) error { return failure }
			},
			wantClass: FailureJournal, wantState: StateAborted,
		},
		{
			name: "mutation",
			configure: func(_ *Runner, _ *journalFunc, mutation *mutationFunc, _ *validatorFunc) {
				mutation.apply = func(context.Context, Repository) error { return failure }
			},
			wantClass: FailureMutation, wantState: StateRolledBack,
		},
		{
			name: "postflight",
			configure: func(_ *Runner, _ *journalFunc, _ *mutationFunc, validator *validatorFunc) {
				*validator = func(context.Context, Repository, View) error { return failure }
			},
			wantClass: FailurePostflight, wantState: StateRolledBack,
		},
		{
			name: "rollback",
			configure: func(r *Runner, _ *journalFunc, mutation *mutationFunc, _ *validatorFunc) {
				mutation.apply = func(context.Context, Repository) error { return failure }
				r.rollback = rollbackFunc(func(context.Context, View, ClassifiedFailure) (*RecoveryReport, error) {
					return &RecoveryReport{State: StateRollbackFailed}, failure
				})
			},
			wantClass: FailureRollback, wantState: StateRollbackFailed,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			journal := &journalFunc{}
			runner := testRunner(journal)
			mutation := mutationFunc{
				name: "test", surfaces: []Surface{SurfaceAdapterArtifacts},
				apply: func(context.Context, Repository) error { return nil },
			}
			validator := validatorFunc(func(context.Context, Repository, View) error { return nil })
			test.configure(runner, journal, &mutation, &validator)
			result, err := runner.Run(context.Background(), Request{
				Command: "stack.test", Mutation: mutation, Validator: validator,
				Policy: Policy{
					RequiredSnapshots:      []Surface{SurfaceAdapterArtifacts},
					AllowedRollbackClasses: []RollbackClass{RollbackAdapterArtifact},
				},
			})
			if err == nil {
				t.Fatal("Run() error = nil")
			}
			if result == nil {
				t.Fatal("Run() result = nil")
			}
			if result.FailureClass != test.wantClass || result.State != test.wantState {
				t.Fatalf("result class/state = %s/%s, want %s/%s", result.FailureClass, result.State, test.wantClass, test.wantState)
			}
			assertEvidenceKinds(t, result.Evidence, "diagnostic")
		})
	}
}

func TestMissingSnapshotCoverageBlocksMutation(t *testing.T) {
	applied := false
	runner := testRunner(NewMemoryJournalStore())
	runner.snapshots = snapshotFunc(func(_ context.Context, id string, _ Repository, _ Preflight, _ Policy) (Snapshot, error) {
		return Snapshot{
			TransactionID: id,
			Coverage:      map[Surface]Coverage{SurfaceIndex: CoveragePartial},
		}, nil
	})
	result, err := runner.Run(context.Background(), Request{
		Command: "stack.stage",
		Mutation: mutationFunc{
			name: "stage", surfaces: []Surface{SurfaceIndex},
			apply: func(context.Context, Repository) error { applied = true; return nil },
		},
		Validator: NoopValidator{},
		Policy:    Policy{RequiredSnapshots: []Surface{SurfaceIndex}},
	})
	if err == nil || result.FailureClass != FailureSnapshot || applied {
		t.Fatalf("result=%#v err=%v applied=%t", result, err, applied)
	}
}

func TestUnsupportedRollbackRequiresManualRecovery(t *testing.T) {
	runner := testRunner(NewMemoryJournalStore())
	result, err := runner.Run(context.Background(), Request{
		Command: "stack.stage",
		Mutation: mutationFunc{
			name: "stage", surfaces: []Surface{SurfaceIndex},
			apply: func(context.Context, Repository) error { return errors.New("mutation failed") },
		},
		Validator: NoopValidator{},
		Policy: Policy{
			RequiredSnapshots:      []Surface{SurfaceAdapterArtifacts},
			AllowedRollbackClasses: []RollbackClass{RollbackRefOnly},
		},
	})
	if err == nil {
		t.Fatal("Run() error = nil")
	}
	if result.RollbackClass != RollbackManualRequired || result.Recovery == nil || !result.Recovery.ManualRequired {
		t.Fatalf("result = %#v", result)
	}
}

func TestDispatcherRejectsReflogOnlyForNonRefRecovery(t *testing.T) {
	dispatcher := Dispatcher{}
	for _, class := range []RollbackClass{
		RollbackIndexOnly, RollbackWorktreeOnly, RollbackRefIndex,
		RollbackRefIndexWorktree, RollbackConflictState, RollbackAdapterArtifact,
	} {
		if err := dispatcher.ValidateReflogOnly(class); err == nil {
			t.Fatalf("ValidateReflogOnly(%s) error = nil", class)
		}
	}
	if err := dispatcher.ValidateReflogOnly(RollbackRefOnly); err != nil {
		t.Fatalf("ValidateReflogOnly(ref_only) error = %v", err)
	}
}

func TestGitObserverAndSnapshotCaptureRepositoryState(t *testing.T) {
	repo := initTestRepository(t)
	if err := os.WriteFile(filepath.Join(repo, "tracked.txt"), []byte("changed\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(repo, "untracked.txt"), []byte("new\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	runGit(t, repo, "add", "tracked.txt")

	observer := GitObserver{StackRefPrefixes: []string{"refs/heads"}}
	preflight, err := observer.Observe(context.Background(), LocalRepository(repo))
	if err != nil {
		t.Fatalf("Observe() error = %v", err)
	}
	if !preflight.IndexDirty || preflight.WorktreeDirty || len(preflight.Untracked) != 1 {
		t.Fatalf("preflight = %#v", preflight)
	}
	snapshot, err := (GitSnapshotStore{}).Capture(
		context.Background(), "tx-test", LocalRepository(repo), preflight,
		Policy{RequiredSnapshots: []Surface{
			SurfaceHead, SurfaceRefs, SurfaceIndex, SurfaceWorktree,
			SurfaceUntracked, SurfaceConflictState, SurfaceAdapterArtifacts, SurfaceOperationInput,
		}, OperationInput: `{"command":"test"}`},
	)
	if err != nil {
		t.Fatalf("Capture() error = %v", err)
	}
	if err := snapshot.Covers([]Surface{
		SurfaceHead, SurfaceRefs, SurfaceIndex, SurfaceWorktree,
		SurfaceUntracked, SurfaceConflictState, SurfaceAdapterArtifacts, SurfaceOperationInput,
	}); err != nil {
		t.Fatal(err)
	}
	if snapshot.IndexArtifact == "" || len(snapshot.Untracked) != 1 {
		t.Fatalf("snapshot = %#v", snapshot)
	}
}

func TestDurableJournalAndEvidence(t *testing.T) {
	root := t.TempDir()
	journal := &JSONLJournalStore{Root: root}
	runner := testRunner(journal)
	runner.evidence = DirectoryEvidenceEmitter{Root: root}

	result, err := runner.Run(context.Background(), Request{
		Command: "stack.noop", Mutation: NoopMutation{}, Validator: NoopValidator{},
		Policy: Policy{
			RequiredSnapshots:      []Surface{SurfaceAdapterArtifacts},
			AllowedRollbackClasses: []RollbackClass{RollbackAdapterArtifact},
		},
	})
	if err != nil {
		t.Fatalf("Run() error = %v", err)
	}
	persisted, err := journal.Entries(context.Background(), result.TransactionID)
	if err != nil {
		t.Fatalf("Entries() error = %v", err)
	}
	if len(persisted) != len(result.Journal) {
		t.Fatalf("persisted journal entries = %d, want %d", len(persisted), len(result.Journal))
	}
	for _, ref := range result.Evidence {
		path := strings.TrimPrefix(ref.URI, "file://")
		if _, err := os.Stat(path); err != nil {
			t.Fatalf("evidence %s: %v", ref.URI, err)
		}
	}
}

func testRunner(journal JournalStore) *Runner {
	runner := NewRunner(
		LocalRepository("/repo"),
		observerFunc(func(context.Context, Repository) (Preflight, error) {
			return Preflight{
				RepoRoot: "/repo", HeadOID: strings.Repeat("a", 40),
				IndexReadable: true, WorktreeReadable: true,
			}, nil
		}),
		snapshotFunc(func(_ context.Context, id string, _ Repository, p Preflight, _ Policy) (Snapshot, error) {
			return Snapshot{
				TransactionID: id, HeadOID: p.HeadOID,
				Coverage: map[Surface]Coverage{
					SurfaceAdapterArtifacts: CoverageComplete,
					SurfaceIndex:            CoverageComplete,
				},
			}, nil
		}),
		journal,
		rollbackFunc(func(context.Context, View, ClassifiedFailure) (*RecoveryReport, error) {
			return &RecoveryReport{State: StateRolledBack, Recovered: true}, nil
		}),
		URIEmitter{},
	)
	runner.now = func() time.Time { return time.Unix(1, 0) }
	runner.newID = func() (string, error) { return "tx-test", nil }
	return runner
}

func assertEvidenceKinds(t *testing.T, evidence []EvidenceRef, kinds ...string) {
	t.Helper()
	for _, kind := range kinds {
		found := false
		for _, ref := range evidence {
			if ref.Kind == kind && ref.Immutable && ref.TransactionID != "" {
				found = true
				break
			}
		}
		if !found {
			t.Fatalf("evidence does not contain kind %q: %#v", kind, evidence)
		}
	}
}

func initTestRepository(t *testing.T) string {
	t.Helper()
	repo := t.TempDir()
	runGit(t, repo, "init")
	runGit(t, repo, "config", "user.name", "Test User")
	runGit(t, repo, "config", "user.email", "test@example.com")
	if err := os.WriteFile(filepath.Join(repo, "tracked.txt"), []byte("initial\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	runGit(t, repo, "add", "tracked.txt")
	runGit(t, repo, "commit", "-m", "initial")
	return repo
}

func runGit(t *testing.T, repo string, args ...string) {
	t.Helper()
	command := exec.Command("git", args...)
	command.Dir = repo
	if output, err := command.CombinedOutput(); err != nil {
		t.Fatalf("git %s: %v\n%s", strings.Join(args, " "), err, output)
	}
}
