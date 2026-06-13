package repo

#Fixture: close({
	id: string & !=""

	purpose: string

	inputs: {
		graph:        #Graph
		workspace?:   #WorkspaceState
		changes?:     [string]: #ChangeUnit
		assignments?: [string]: #Assignment
		operations?:  [string]: #Operation
		taskGroups?:  [string]: #TaskGroup
		projections?: [string]: #Projection
	}

	expected: {
		valid: bool
		failingGates?:     [...string]
		allowedOperations?: [...string]
		blockedOperations?: [...string]
	}
})

fixtureClasses: {
	validSingleBranch: #Fixture & {
		id: "valid-single-branch"
		purpose: "Normal Git mode with no managed-workspace assumptions."
		expected: valid: true
	}

	validManagedWorkspace: #Fixture & {
		id: "valid-managed-workspace"
		purpose: "GitButler workspace with assignments."
		expected: valid: true
	}

	unassignedChange: #Fixture & {
		id: "unassigned-change"
		purpose: "Worktree change exists but no assignment exists yet."
		expected: valid: true
	}

	illegalAssignment: #Fixture & {
		id: "illegal-assignment"
		purpose: "Change is assigned to a route that cannot touch its surface."
		expected: {
			valid: false
			failingGates: ["gate.git-representable-mutation-target"]
		}
	}

	projectionOnlyLabel: #Fixture & {
		id: "projection-only-label"
		purpose: "A semantic label exists but cannot drive mutation."
		expected: {
			valid: false
			failingGates: ["gate.projection-non-authority", "gate.label-derived"]
		}
	}

	staleWorkspaceProjection: #Fixture & {
		id: "stale-workspace-projection"
		purpose: "Workspace projection differs from the graph source of truth."
		expected: {
			valid: false
			failingGates: ["gate.graph-before-projection"]
		}
	}

	dryRunRequired: #Fixture & {
		id: "dry-run-required"
		purpose: "Mutating operation lacks required dry-run or approval."
		expected: {
			valid: false
			failingGates: ["gate.dry-run-required", "gate.approval-required"]
		}
	}

	snapshotRequired: #Fixture & {
		id: "snapshot-required"
		purpose: "Mutation route requires an oplog snapshot."
		expected: {
			valid: false
			failingGates: ["gate.snapshot-required"]
		}
	}

	parallelReview: #Fixture & {
		id: "parallel-review"
		purpose: "Codex subagents inspect separate concerns with explicit VCS scope."
		expected: valid: true
	}

	repairLoop: #Fixture & {
		id: "repair-loop"
		purpose: "Codex implementation and validation feedback loop over explicit task groups."
		expected: valid: true
	}
}

minimumWorkflowGateAssertions: [
	"Graph validates before projection.",
	"Projection never decides topology.",
	"Mutation target is commit/ref/change-unit, not component/seed/bundle label.",
	"Every write operation has mode: plan | dry-run | mutate.",
	"Every mutate operation has an approval gate.",
	"Every Codex task declares sandbox.",
	"Every subagent task declares VCS scope.",
	"Every but-sdk operation is represented as an adapter route.",
	"Every generated projection is non-authoritative.",
	"Every semantic label is derived.",
]
