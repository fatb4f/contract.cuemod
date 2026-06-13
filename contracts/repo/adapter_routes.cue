package repo

#ButSDKRoute: close({
	id: string & !=""

	api: string & !=""

	operationKind: #OperationKind

	mode: #OperationMode

	inputSchema:  string & !=""
	outputSchema: string & !=""

	requiresExclusiveWorktree: bool | *false
	recordsOplogSnapshot:     bool | *false
	hasDryRunVariant:          bool | *false

	gates: [...string]
})

#GitCLIRoute: close({
	id: string & !=""

	command: string & !=""

	operationKind: #OperationKind
	mode:          #OperationMode

	role: "fallback" | "verification" | "escape-hatch"

	inputs:  [...string]
	outputs: [...string]

	gates: [...string]
})

#MCPResource: close({
	uri: string & !=""

	source:
		"vcs-graph" |
		"workspace" |
		"operation-registry" |
		"agent-registry" |
		"gate-registry"

	authoritative: bool
	derived:       bool
})

#MCPTool: close({
	name: string & !=""

	plane: "read" | "plan" | "validate" | "mutate"

	inputs:  [...string]
	outputs: [...string]

	allowedAdapters: [...string]

	gates: [...string]

	mayMutate: bool | *false
})

#CodexSDKRoute: close({
	id: string & !=""

	api: string & !=""

	role: "thread" | "prompt" | "agent" | "sandbox" | "result"

	inputs:  [...string]
	outputs: [...string]

	gates: [...string]
})

readPlaneResources: {
	graphCurrent: #MCPResource & {
		uri: "repo://vcs/graph/current"
		source: "vcs-graph"
		authoritative: true
		derived: false
	}

	workspaceCurrent: #MCPResource & {
		uri: "repo://vcs/workspace/current"
		source: "workspace"
		authoritative: false
		derived: true
	}

	operationsAvailable: #MCPResource & {
		uri: "repo://vcs/operations/available"
		source: "operation-registry"
		authoritative: true
		derived: false
	}

	taskGroups: #MCPResource & {
		uri: "repo://agent/task-groups"
		source: "agent-registry"
		authoritative: true
		derived: false
	}

	gatesCurrent: #MCPResource & {
		uri: "repo://gates/current"
		source: "gate-registry"
		authoritative: true
		derived: false
	}
}

toolPlane: {
	graphValidate: #MCPTool & {
		name: "repo.graph.validate"
		plane: "validate"
		inputs: ["vcs.graph"]
		outputs: ["gate-result"]
		allowedAdapters: ["cue"]
		gates: []
	}

	vcsMutationPlan: #MCPTool & {
		name: "repo.vcs.mutationPlan"
		plane: "plan"
		inputs: ["vcs.graph", "workflow.route"]
		outputs: ["workflow.operation.plan"]
		allowedAdapters: ["but-sdk", "git-cli"]
		gates: ["gate.graph-before-projection", "gate.git-representable-mutation-target"]
	}

	vcsDryRun: #MCPTool & {
		name: "repo.vcs.dryRun"
		plane: "plan"
		inputs: ["workflow.operation.plan"]
		outputs: ["workflow.operation.dry-run-result"]
		allowedAdapters: ["but-sdk", "git-cli"]
		gates: ["gate.dry-run-required"]
	}

	vcsApplyMutation: #MCPTool & {
		name: "repo.vcs.applyMutation"
		plane: "mutate"
		inputs: ["workflow.operation.dry-run-result", "gate.approval"]
		outputs: ["vcs.graph", "vcs.workspace", "vcs.oplog"]
		allowedAdapters: ["but-sdk"]
		gates: ["gate.graph-before-projection", "gate.approval-required"]
		mayMutate: true
	}

	agentTaskGroupPlan: #MCPTool & {
		name: "repo.agent.taskGroupPlan"
		plane: "plan"
		inputs: ["workflow.task_group"]
		outputs: ["agent.pipeline.plan"]
		allowedAdapters: ["codex-sdk"]
		gates: ["gate.codex-sandbox-required", "gate.codex-vcs-scope-required"]
	}
}

butSDKRoutes: {
	changesInWorktree: #ButSDKRoute & {
		id: "but-sdk.changesInWorktree"
		api: "changesInWorktree"
		operationKind: "inspect"
		mode: "read"
		inputSchema: "vcs.repository"
		outputSchema: "vcs.change_unit[]"
	}

	assignHunk: #ButSDKRoute & {
		id: "but-sdk.assignHunk"
		api: "assignHunk"
		operationKind: "assign-change"
		mode: "mutate"
		inputSchema: "vcs.assignment"
		outputSchema: "vcs.assignment"
		requiresExclusiveWorktree: true
		recordsOplogSnapshot: true
		gates: ["gate.graph-before-projection", "gate.git-representable-mutation-target", "gate.approval-required"]
	}

	commitCreate: #ButSDKRoute & {
		id: "but-sdk.commitCreate"
		api: "commitCreate"
		operationKind: "create-commit"
		mode: "mutate"
		inputSchema: "workflow.commit-create-input"
		outputSchema: "vcs.commit"
		requiresExclusiveWorktree: true
		recordsOplogSnapshot: true
		hasDryRunVariant: true
		gates: ["gate.graph-before-projection", "gate.dry-run-required", "gate.approval-required"]
	}

	unapplyStack: #ButSDKRoute & {
		id: "but-sdk.unapplyStack"
		api: "unapplyStack"
		operationKind: "unapply-stack"
		mode: "mutate"
		inputSchema: "workflow.unapply-input"
		outputSchema: "vcs.workspace"
		requiresExclusiveWorktree: true
		recordsOplogSnapshot: true
		gates: ["gate.graph-before-projection", "gate.dry-run-required", "gate.approval-required"]
	}

	workspaceIntegrateUpstream: #ButSDKRoute & {
		id: "but-sdk.workspaceIntegrateUpstream"
		api: "workspaceIntegrateUpstream"
		operationKind: "integrate-upstream"
		mode: "mutate"
		inputSchema: "workflow.integrate-upstream-input"
		outputSchema: "vcs.workspace"
		requiresExclusiveWorktree: true
		recordsOplogSnapshot: true
		gates: ["gate.graph-before-projection", "gate.dry-run-required", "gate.approval-required"]
	}
}
