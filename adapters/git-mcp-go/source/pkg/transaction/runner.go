package transaction

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"slices"
	"sync"
	"time"
)

type Runner struct {
	repo      Repository
	observer  PreflightObserver
	snapshots SnapshotStore
	journals  JournalStore
	mutations MutationAdapter
	rollback  RollbackDispatcher
	evidence  EvidenceEmitter
	now       Clock
	newID     func() (string, error)
}

func NewRunner(
	repo Repository,
	observer PreflightObserver,
	snapshots SnapshotStore,
	journals JournalStore,
	rollback RollbackDispatcher,
	evidence EvidenceEmitter,
) *Runner {
	return &Runner{
		repo: repo, observer: observer, snapshots: snapshots, journals: journals,
		mutations: GuardedMutationAdapter{}, rollback: rollback, evidence: evidence,
		now: time.Now, newID: transactionID,
	}
}

func (r *Runner) Run(ctx context.Context, req Request) (*Result, error) {
	if err := validateRequest(req); err != nil {
		return nil, err
	}
	id, err := r.newID()
	if err != nil {
		return nil, fmt.Errorf("create transaction ID: %w", err)
	}
	tx := &runtimeTransaction{
		id: id, command: req.Command, state: StatePlanned, repo: r.repo,
		journals: r.journals, now: r.now,
	}

	preflight, err := r.observer.Observe(ctx, r.repo)
	if err != nil {
		return r.abort(ctx, tx, FailurePreflight, err)
	}
	if err := preflight.Validate(); err != nil {
		return r.abort(ctx, tx, FailurePreflight, err)
	}
	tx.preflight = preflight
	if req.PreflightValidator != nil {
		if err := req.PreflightValidator.ValidatePreflight(ctx, r.repo, preflight); err != nil {
			return r.abort(ctx, tx, FailurePreflight, err)
		}
	}
	if err := tx.transition(StatePreflighted); err != nil {
		return nil, err
	}

	snapshot, err := r.snapshots.Capture(ctx, id, r.repo, preflight, req.Policy)
	if err != nil {
		return r.abort(ctx, tx, FailureSnapshot, err)
	}
	if err := snapshot.Covers(req.Policy.RequiredSnapshots); err != nil {
		return r.abort(ctx, tx, FailureSnapshot, err)
	}
	tx.snapshot = snapshot
	if err := tx.transition(StateSnapshotCreated); err != nil {
		return nil, err
	}
	if err := tx.append(ctx, PhasePreflight, "observe", req.Command, "", "passed", RollbackNone); err != nil {
		return r.abort(ctx, tx, FailureJournal, err)
	}
	if err := tx.append(ctx, PhaseSnapshot, "capture", req.Command, "", "complete", RollbackNone); err != nil {
		return r.abort(ctx, tx, FailureJournal, err)
	}
	if err := tx.append(ctx, PhaseJournal, "open", req.Command, "", "open", RollbackNone); err != nil {
		return r.abort(ctx, tx, FailureJournal, err)
	}
	if err := tx.transition(StateJournalOpened); err != nil {
		return nil, err
	}

	if err := tx.append(ctx, PhaseMutation, "start", req.Mutation.Name(), "", "started", RollbackNone); err != nil {
		return r.abort(ctx, tx, FailureJournal, err)
	}
	if err := tx.transition(StateMutationStarted); err != nil {
		return nil, err
	}
	if err := r.mutations.Apply(ctx, req.Mutation, r.repo); err != nil {
		return r.failAndRollback(ctx, tx, req, FailureMutation, err)
	}
	if err := tx.transition(StateMutationApplied); err != nil {
		return nil, err
	}
	if err := tx.append(ctx, PhaseMutation, "apply", req.Mutation.Name(), "started", "applied", RollbackNone); err != nil {
		return r.failAndRollback(ctx, tx, req, FailureJournal, err)
	}

	if err := tx.append(ctx, PhasePostflight, "start", req.Validator.Name(), "", "started", RollbackNone); err != nil {
		return r.failAndRollback(ctx, tx, req, FailureJournal, err)
	}
	if err := tx.transition(StatePostflightStarted); err != nil {
		return nil, err
	}
	if err := req.Validator.Validate(ctx, r.repo, tx); err != nil {
		return r.failAndRollback(ctx, tx, req, FailurePostflight, err)
	}
	if err := tx.append(ctx, PhasePostflight, "validate", req.Validator.Name(), "started", "passed", RollbackNone); err != nil {
		return r.failAndRollback(ctx, tx, req, FailureJournal, err)
	}
	rollbackClass := classifyRollback(req.Mutation.AffectedSurfaces())
	if !slices.Contains(req.Policy.AllowedRollbackClasses, rollbackClass) {
		rollbackClass = RollbackManualRequired
	}
	if err := tx.append(ctx, PhaseCommit, "commit", req.Command, "", "committed", rollbackClass); err != nil {
		return r.failAndRollback(ctx, tx, req, FailureJournal, err)
	}
	evidence, emitErr := r.evidence.Emit(ctx, stateView{View: tx, state: StateCommitted}, nil, "")
	if emitErr != nil {
		return r.failAndRollback(ctx, tx, req, FailureJournal, fmt.Errorf("emit transaction evidence: %w", emitErr))
	}
	if err := tx.transition(StateCommitted); err != nil {
		return nil, err
	}

	result := tx.result(true, "", RollbackNone, nil, evidence)
	return result, nil
}

type stateView struct {
	View
	state State
}

func (v stateView) State() State { return v.state }

func (r *Runner) abort(ctx context.Context, tx *runtimeTransaction, class FailureClass, cause error) (*Result, error) {
	if err := tx.transition(StateAborted); err != nil {
		return nil, errors.Join(cause, err)
	}
	_ = tx.append(ctx, PhaseAbort, "abort", tx.command, "", string(class), RollbackNone)
	evidence, emitErr := r.evidence.Emit(ctx, tx, nil, class)
	result := tx.result(false, class, RollbackNone, nil, evidence)
	return result, errors.Join(cause, emitErr)
}

func (r *Runner) failAndRollback(
	ctx context.Context,
	tx *runtimeTransaction,
	req Request,
	class FailureClass,
	cause error,
) (*Result, error) {
	rollbackClass := classifyRollback(req.Mutation.AffectedSurfaces())
	if !slices.Contains(req.Policy.AllowedRollbackClasses, rollbackClass) {
		rollbackClass = RollbackManualRequired
	}
	if err := tx.transition(StateRollbackStarted); err != nil {
		return nil, errors.Join(cause, err)
	}
	_ = tx.append(ctx, PhaseRollback, "start", req.Mutation.Name(), "", string(class), rollbackClass)

	failure := ClassifiedFailure{
		Class: class, RollbackClass: rollbackClass, Cause: cause,
		Surfaces: req.Mutation.AffectedSurfaces(),
	}
	recovery, rollbackErr := r.rollback.Rollback(ctx, tx, failure)
	if recovery == nil {
		recovery = &RecoveryReport{
			State: StateRollbackFailed, ManualRequired: true,
			Notes: []string{"rollback dispatcher returned no recovery report"},
		}
	}
	if rollbackClass == RollbackManualRequired {
		recovery.State = StateRollbackPartial
		recovery.Recovered = false
		recovery.ManualRequired = true
	}
	finalState := recovery.State
	if finalState != StateRolledBack && finalState != StateRollbackPartial && finalState != StateRollbackFailed {
		finalState = StateRollbackFailed
		recovery.State = finalState
		recovery.ManualRequired = true
	}
	if rollbackErr != nil {
		finalState = StateRollbackFailed
		recovery.State = finalState
		recovery.ManualRequired = true
		class = FailureRollback
	}
	if err := tx.transition(finalState); err != nil {
		return nil, errors.Join(cause, rollbackErr, err)
	}
	_ = tx.append(ctx, PhaseRollback, "finish", req.Mutation.Name(), "started", string(finalState), rollbackClass)
	evidence, emitErr := r.evidence.Emit(ctx, tx, recovery, class)
	recovery.Evidence = append(recovery.Evidence, evidence...)
	result := tx.result(false, class, rollbackClass, recovery, evidence)
	return result, errors.Join(cause, rollbackErr, emitErr)
}

func validateRequest(req Request) error {
	if len(req.Command) < len("stack.") || req.Command[:len("stack.")] != "stack." {
		return fmt.Errorf("transaction command %q must use stack.* namespace", req.Command)
	}
	if req.Mutation == nil || req.Validator == nil {
		return errors.New("transaction requires mutation and validator")
	}
	return nil
}

func classifyRollback(surfaces []Surface) RollbackClass {
	has := func(surface Surface) bool { return slices.Contains(surfaces, surface) }
	switch {
	case has(SurfaceConflictState):
		return RollbackConflictState
	case has(SurfaceAdapterArtifacts) && len(surfaces) == 1:
		return RollbackAdapterArtifact
	case has(SurfaceHead) || has(SurfaceRefs):
		if has(SurfaceWorktree) || has(SurfaceUntracked) {
			return RollbackRefIndexWorktree
		}
		if has(SurfaceIndex) {
			return RollbackRefIndex
		}
		return RollbackRefOnly
	case has(SurfaceIndex):
		return RollbackIndexOnly
	case has(SurfaceWorktree) || has(SurfaceUntracked):
		return RollbackWorktreeOnly
	default:
		return RollbackManualRequired
	}
}

func transactionID() (string, error) {
	var random [16]byte
	if _, err := rand.Read(random[:]); err != nil {
		return "", err
	}
	return "tx-" + hex.EncodeToString(random[:]), nil
}

type runtimeTransaction struct {
	mu        sync.RWMutex
	id        string
	command   string
	state     State
	repo      Repository
	preflight Preflight
	snapshot  Snapshot
	journal   []JournalEntry
	journals  JournalStore
	now       Clock
}

func (t *runtimeTransaction) ID() string           { return t.id }
func (t *runtimeTransaction) Command() string      { return t.command }
func (t *runtimeTransaction) Preflight() Preflight { return t.preflight }
func (t *runtimeTransaction) Snapshot() Snapshot   { return t.snapshot }

func (t *runtimeTransaction) State() State {
	t.mu.RLock()
	defer t.mu.RUnlock()
	return t.state
}

func (t *runtimeTransaction) Journal() []JournalEntry {
	t.mu.RLock()
	defer t.mu.RUnlock()
	return append([]JournalEntry(nil), t.journal...)
}

func (t *runtimeTransaction) transition(next State) error {
	t.mu.Lock()
	defer t.mu.Unlock()
	if err := validateTransition(t.state, next); err != nil {
		return err
	}
	t.state = next
	return nil
}

func (t *runtimeTransaction) append(
	ctx context.Context,
	phase JournalPhase,
	action, target, before, after string,
	rollbackClass RollbackClass,
) error {
	t.mu.Lock()
	entry := JournalEntry{
		TransactionID: t.id, Seq: len(t.journal), Phase: phase, Action: action,
		Target: target, Before: before, After: after, RollbackClass: rollbackClass,
		Timestamp: t.now().UTC(),
	}
	t.mu.Unlock()
	if err := t.journals.Append(ctx, entry); err != nil {
		return err
	}
	t.mu.Lock()
	t.journal = append(t.journal, entry)
	t.mu.Unlock()
	return nil
}

func (t *runtimeTransaction) result(
	ok bool,
	failure FailureClass,
	rollbackClass RollbackClass,
	recovery *RecoveryReport,
	evidence []EvidenceRef,
) *Result {
	return &Result{
		TransactionID: t.id, Command: t.command, State: t.State(), OK: ok,
		FailureClass: failure, RollbackClass: rollbackClass, Recovery: recovery,
		Evidence: evidence, Preflight: t.preflight, Snapshot: t.snapshot,
		Journal: t.Journal(),
	}
}
