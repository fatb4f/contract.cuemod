package repo

#MutationRoute: close({
	id: string & !=""

	operation: #OperationKind

	// Mutation targets must be Git-representable source objects.
	target: {
		ref?:        string
		commit?:     string
		changeUnit?: string
	}

	planOperation:   string
	dryRunOperation?: string
	mutateOperation?: string

	requiresHumanApproval: bool | *true
	requiresGraphValidation: bool | *true
	requiresProjectionRefresh: bool | *true

	gates: [...string]
})

#AgentRole:
	"explorer" |
	"planner" |
	"implementer" |
	"validator" |
	"reviewer" |
	"publisher"

#Sandbox: "read-only" | "workspace-write" | "full-access"

#AgentTask: close({
	id: string & !=""

	role:    #AgentRole
	sandbox: #Sandbox

	inputs:          [...string]
	expectedOutputs: [...string]

	allowedTools: [...string]
	forbiddenTools?: [...string]

	vcsScope: {
		refs?:        [...string]
		commits?:     [...string]
		changeUnits?: [...string]
		surfaces?:    [...string]
	}

	gates: [...string]
})

#TaskGroupPattern:
	"explore-only" |
	"plan-only" |
	"plan-then-implement" |
	"parallel-review" |
	"repair-loop" |
	"projection-refresh" |
	"branch-publication"

#TaskGroup: close({
	id: string & !=""

	pattern: #TaskGroupPattern

	agents: [...#AgentTask]

	concurrency: int & >=1
	maxThreads?: int

	vcsOperationRoute?: string

	requiresHumanApproval: bool | *true
	gates: [...string]
})

#GateKind:
	"graph-validation" |
	"projection-nonauthority" |
	"mutation-target" |
	"dry-run-required" |
	"snapshot-required" |
	"approval-required" |
	"sandbox-required" |
	"vcs-scope-required" |
	"adapter-route-required" |
	"label-derived"

#Gate: close({
	id: string & !=""
	kind: #GateKind

	inputs: [...string]

	failureMessage: string

	blocksMutation: bool | *true
})

requiredWorkflowGates: {
	graphBeforeProjection: #Gate & {
		id: "gate.graph-before-projection"
		kind: "graph-validation"
		failureMessage: "Graph must validate before projection is generated."
	}

	projectionNonAuthority: #Gate & {
		id: "gate.projection-non-authority"
		kind: "projection-nonauthority"
		failureMessage: "Projection cannot decide topology or mutation target."
	}

	gitRepresentableMutationTarget: #Gate & {
		id: "gate.git-representable-mutation-target"
		kind: "mutation-target"
		failureMessage: "Mutation target must be commit, ref, or change-unit."
	}

	dryRunRequired: #Gate & {
		id: "gate.dry-run-required"
		kind: "dry-run-required"
		failureMessage: "Mutation route requires dry-run when available."
	}

	approvalRequired: #Gate & {
		id: "gate.approval-required"
		kind: "approval-required"
		failureMessage: "Mutating operation requires approval."
	}

	sandboxRequired: #Gate & {
		id: "gate.codex-sandbox-required"
		kind: "sandbox-required"
		failureMessage: "Every Codex task must declare sandbox."
	}

	vcsScopeRequired: #Gate & {
		id: "gate.codex-vcs-scope-required"
		kind: "vcs-scope-required"
		failureMessage: "Every subagent task must declare VCS scope."
	}

	butSDKRouteRequired: #Gate & {
		id: "gate.but-sdk-route-required"
		kind: "adapter-route-required"
		failureMessage: "Every but-sdk operation must be represented as an adapter route."
	}

	labelDerived: #Gate & {
		id: "gate.label-derived"
		kind: "label-derived"
		failureMessage: "Semantic labels are derived and non-authoritative."
	}
}
