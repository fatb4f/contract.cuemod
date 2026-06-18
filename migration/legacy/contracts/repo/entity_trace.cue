package repo

#TraceScheme:
	"git" |
	"but-sdk" |
	"vcs" |
	"workflow" |
	"mcp" |
	"codex-sdk" |
	"projection"

#TraceStep: close({
	id: string & !=""

	scheme: #TraceScheme

	entity: string & !=""

	inputs: [...string]
	outputs: [...string]

	authoritative: bool
	derived:       bool
})

#EntityTrace: close({
	id: string & !=""

	entity: string & !=""

	steps: [...#TraceStep]

	invariants: {
		sourcePrimitiveFirst: true
		projectionLast:       true
		noProjectionMutation: true
	}
})

traceHunk001: #EntityTrace & {
	id:     "trace.hunk-001"
	entity: "changeUnit:hunk-001"

	steps: [
		{
			id:     "git.diff"
			scheme: "git"
			entity: "worktree:hunk-001"
			inputs: ["repository"]
			outputs: ["raw-diff"]
			authoritative: true
			derived:       false
		},
		{
			id:     "but-sdk.changesInWorktree"
			scheme: "but-sdk"
			entity: "worktree:hunk-001"
			inputs: ["repository"]
			outputs: ["changeUnit:hunk-001"]
			authoritative: true
			derived:       false
		},
		{
			id:     "vcs.changeUnit"
			scheme: "vcs"
			entity: "changeUnit:hunk-001"
			inputs: ["but-sdk.changesInWorktree"]
			outputs: ["vcs.ChangeUnit"]
			authoritative: true
			derived:       false
		},
		{
			id:     "workflow.assignmentPlan"
			scheme: "workflow"
			entity: "assignment:hunk-001"
			inputs: ["changeUnit:hunk-001", "ref:vb-contract"]
			outputs: ["operation:assign-change.plan"]
			authoritative: true
			derived:       false
		},
		{
			id:     "mcp.repo.vcs.dryRun"
			scheme: "mcp"
			entity: "operation:assign-change.dry-run"
			inputs: ["operation:assign-change.plan"]
			outputs: ["dry-run-result"]
			authoritative: false
			derived:       false
		},
		{
			id:     "codex.validator"
			scheme: "codex-sdk"
			entity: "task:validate-assignment"
			inputs: ["dry-run-result", "graph"]
			outputs: ["validation-report"]
			authoritative: false
			derived:       true
		},
		{
			id:     "projection.component-label"
			scheme: "projection"
			entity: "label:vb-contract"
			inputs: ["graph", "workspace", "assignment:hunk-001"]
			outputs: ["projection.label"]
			authoritative: false
			derived:       true
		},
	]

	invariants: {
		sourcePrimitiveFirst: true
		projectionLast:       true
		noProjectionMutation: true
	}
}
