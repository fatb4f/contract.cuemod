package repo

#VCSWorkflow: close({
	repository: #Repository

	graph:     #Graph
	workspace: #WorkspaceState

	changes:     [string]: #ChangeUnit
	assignments: [string]: #Assignment

	operations: [string]: #Operation
	taskGroups: [string]: #TaskGroup

	projections: [string]: #Projection
	gates:       [string]: #Gate
})

#Repository: close({
	id:   string & !=""
	root: string & !=""

	vcs: "git"

	projectHandle?: string
})

#Commit: close({
	sha: string & !=""

	parents: [...string]
	tree?: string

	message?: string
	author?:  string
})

#RefKind: "local" | "remote" | "virtual" | "target" | "workspace"

#Ref: close({
	name: string & !=""
	kind: #RefKind

	pointsTo?: string
	upstream?:  string
})

#GraphEdgeKind: "parent" | "reachability" | "dependency" | "contains" | "targets"

#GraphEdge: close({
	from: string & !=""
	to:   string & !=""
	kind: #GraphEdgeKind
})

#TargetFrame: close({
	targetRef:    string & !=""
	targetCommit: string & !=""
})

#Graph: close({
	commits: [string]: #Commit
	refs:    [string]: #Ref
	edges:   [...#GraphEdge]

	target: #TargetFrame
})

#WorkspaceState: close({
	id: string & !=""

	repository: string & !=""
	target:     #TargetFrame

	refInfo?: {
		currentRef?: string
		baseCommit?: string
		headCommit?: string
	}

	changeUnits: [...string]
	assignments: [...string]

	// Workspace/refinfo views are derived, compressed, and may be lossy.
	lossy: bool | *true
	derivedFromGraphRevision?: string
})

#ChangeUnitKind: "worktree-change" | "tree-change" | "hunk" | "file"

#ChangeUnit: close({
	id:   string & !=""
	kind: #ChangeUnitKind

	path?: string

	baseCommit?: string
	headCommit?: string

	parentChange?: string

	// Surface is a derived projection hint, never a mutation target.
	surface?: string
})

#Assignment: close({
	id: string & !=""

	changeUnit: string & !=""

	target: {
		ref?:    string
		commit?: string
		route?:  string
	}

	source: "but-sdk" | "git" | "mcp" | "manual"

	gates: [...string]
})

#OperationKind:
	"inspect" |
	"assign-change" |
	"create-branch" |
	"apply-branch" |
	"unapply-stack" |
	"create-commit" |
	"rewrite-commit" |
	"move-commit" |
	"squash-commit" |
	"uncommit" |
	"integrate-upstream" |
	"push" |
	"restore-snapshot"

#OperationSource: "but-sdk" | "git" | "codex-sdk" | "mcp"

#OperationMode: "read" | "plan" | "dry-run" | "mutate"

#Operation: close({
	id:   string & !=""
	kind: #OperationKind

	source: #OperationSource
	mode:   #OperationMode

	inputs:  [...string]
	outputs: [...string]

	requiresExclusiveWorktree: bool | *false
	recordsOplogSnapshot:     bool | *false

	gates: [...string]
})

#OplogSnapshot: close({
	id: string & !=""

	operation: string & !=""

	beforeGraphRevision?: string
	afterGraphRevision?:  string

	restoreOperation?: string
})

#MutationInvariant: close({
	targetMustBeGitRepresentable:          true
	selectorDurability:                   "operation-local-only"
	requireDryRunWhenAvailable:           true
	requireGraphValidationBeforeMutation: true
	requireProjectionRefreshAfterMutation: true
})

#Projection: close({
	id: string & !=""

	kind: "surface" | "module" | "label" | "inventory"

	inputs: [...string]

	authoritative: false
	derived:       true

	labels?: [...string]
})
