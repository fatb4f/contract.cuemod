package transaction

import (
	"context"
	"errors"
	"fmt"
	"regexp"
	"time"
)

var oidPattern = regexp.MustCompile(`^[0-9a-f]{40}$`)

type State string

const (
	StatePlanned           State = "planned"
	StatePreflighted       State = "preflighted"
	StateSnapshotCreated   State = "snapshot_created"
	StateJournalOpened     State = "journal_opened"
	StateMutationStarted   State = "mutation_started"
	StateMutationApplied   State = "mutation_applied"
	StatePostflightStarted State = "postflight_started"
	StateCommitted         State = "committed"
	StateRollbackStarted   State = "rollback_started"
	StateRolledBack        State = "rolled_back"
	StateRollbackPartial   State = "rollback_partial"
	StateRollbackFailed    State = "rollback_failed"
	StateAborted           State = "aborted"
)

type Surface string

const (
	SurfaceHead             Surface = "head"
	SurfaceRefs             Surface = "refs"
	SurfaceIndex            Surface = "index"
	SurfaceWorktree         Surface = "worktree"
	SurfaceUntracked        Surface = "untracked"
	SurfaceConflictState    Surface = "conflict_state"
	SurfaceAdapterArtifacts Surface = "adapter_artifacts"
	SurfaceOperationInput   Surface = "operation_input"
)

type Coverage string

const (
	CoverageComplete    Coverage = "complete"
	CoveragePartial     Coverage = "partial"
	CoverageNotRequired Coverage = "not_required"
)

type FailureClass string

const (
	FailurePreflight  FailureClass = "preflight_failed"
	FailureSnapshot   FailureClass = "snapshot_failed"
	FailureJournal    FailureClass = "journal_failed"
	FailureMutation   FailureClass = "mutation_failed"
	FailurePostflight FailureClass = "postflight_failed"
	FailureRollback   FailureClass = "rollback_failed"
)

type RollbackClass string

const (
	RollbackNone             RollbackClass = "none"
	RollbackRefOnly          RollbackClass = "ref_only"
	RollbackIndexOnly        RollbackClass = "index_only"
	RollbackWorktreeOnly     RollbackClass = "worktree_only"
	RollbackRefIndex         RollbackClass = "ref_index"
	RollbackRefIndexWorktree RollbackClass = "ref_index_worktree"
	RollbackConflictState    RollbackClass = "conflict_state"
	RollbackAdapterArtifact  RollbackClass = "adapter_artifact"
	RollbackManualRequired   RollbackClass = "manual_required"
)

type JournalPhase string

const (
	PhasePreflight  JournalPhase = "preflight"
	PhaseSnapshot   JournalPhase = "snapshot"
	PhaseJournal    JournalPhase = "journal"
	PhaseMutation   JournalPhase = "mutation"
	PhasePostflight JournalPhase = "postflight"
	PhaseCommit     JournalPhase = "commit"
	PhaseRollback   JournalPhase = "rollback"
	PhaseAbort      JournalPhase = "abort"
)

type Preflight struct {
	RepoRoot             string
	HeadOID              string
	HeadRef              string
	IndexReadable        bool
	WorktreeReadable     bool
	IndexDirty           bool
	WorktreeDirty        bool
	Untracked            []string
	ConflictStatePresent bool
	RelevantRefs         map[string]string
	AdapterArtifacts     []string
	Guards               []Guard
}

type Guard struct {
	Name   string
	Pass   bool
	Reason string
}

func (p Preflight) Validate() error {
	if p.RepoRoot == "" || p.HeadOID == "" {
		return errors.New("preflight did not identify repository root and HEAD")
	}
	if !p.IndexReadable || !p.WorktreeReadable {
		return errors.New("repository index or worktree is unreadable")
	}
	for _, guard := range p.Guards {
		if !guard.Pass {
			return fmt.Errorf("preflight guard %q failed: %s", guard.Name, guard.Reason)
		}
	}
	return nil
}

type Snapshot struct {
	TransactionID string
	Coverage      map[Surface]Coverage
	HeadOID       string
	HeadRef       string
	Refs          map[string]string
	IndexTreeOID  string
	IndexArtifact string
	WorktreePatch string
	Untracked     []string
	ConflictState string
	Artifacts     []string
	ArtifactState map[string]*string
	Operation     string
}

func (s Snapshot) Covers(required []Surface) error {
	for _, surface := range required {
		if s.Coverage[surface] != CoverageComplete {
			return fmt.Errorf("required snapshot surface %q has coverage %q", surface, s.Coverage[surface])
		}
	}
	return nil
}

type JournalEntry struct {
	TransactionID string
	Seq           int
	Phase         JournalPhase
	Action        string
	Target        string
	Before        string
	After         string
	RollbackClass RollbackClass
	Timestamp     time.Time
}

type EvidenceRef struct {
	TransactionID string `json:"transactionID"`
	Kind          string `json:"kind"`
	URI           string `json:"uri"`
	Immutable     bool   `json:"immutable"`
}

type RecoveryReport struct {
	State          State
	Recovered      bool
	ManualRequired bool
	Notes          []string
	Evidence       []EvidenceRef
}

type Result struct {
	TransactionID string
	Command       string
	State         State
	OK            bool
	FailureClass  FailureClass
	RollbackClass RollbackClass
	Recovery      *RecoveryReport
	Evidence      []EvidenceRef
	Preflight     Preflight
	Snapshot      Snapshot
	Journal       []JournalEntry
}

type Policy struct {
	RequiredSnapshots      []Surface
	AllowedRollbackClasses []RollbackClass
	UntrackedPolicy        string
	OperationInput         string
	AdapterArtifactPaths   []string
}

type Request struct {
	Command            string
	PreflightValidator PreflightValidator
	Mutation           Mutation
	Validator          Validator
	Policy             Policy
}

type TransactionState = State
type TransactionRequest = Request
type TransactionPolicy = Policy
type TransactionResult = Result

type TransactionRunner interface {
	Run(context.Context, TransactionRequest) (*TransactionResult, error)
}

type Repository interface {
	Root() string
}

type Mutation interface {
	Name() string
	AffectedSurfaces() []Surface
	Apply(context.Context, Repository) error
}

type MutationAdapter interface {
	Apply(context.Context, Mutation, Repository) error
}

type Validator interface {
	Name() string
	Validate(context.Context, Repository, View) error
}

type View interface {
	ID() string
	State() State
	Command() string
	Preflight() Preflight
	Snapshot() Snapshot
	Journal() []JournalEntry
}

type PreflightObserver interface {
	Observe(context.Context, Repository) (Preflight, error)
}

type PreflightValidator interface {
	ValidatePreflight(context.Context, Repository, Preflight) error
}

type SnapshotStore interface {
	Capture(context.Context, string, Repository, Preflight, Policy) (Snapshot, error)
}

type JournalStore interface {
	Append(context.Context, JournalEntry) error
	Entries(context.Context, string) ([]JournalEntry, error)
}

type ClassifiedFailure struct {
	Class         FailureClass
	RollbackClass RollbackClass
	Cause         error
	Surfaces      []Surface
}

type RollbackDispatcher interface {
	Rollback(context.Context, View, ClassifiedFailure) (*RecoveryReport, error)
}

type EvidenceEmitter interface {
	Emit(context.Context, View, *RecoveryReport, FailureClass) ([]EvidenceRef, error)
}

type Clock func() time.Time
