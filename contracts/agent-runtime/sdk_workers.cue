package agentruntime

import "list"

#SDKWorkerKind:
	"projection-worker" |
	"fixture-worker" |
	"validation-worker" |
	"git-worker"

#WorkerAction:
	"inspect" |
	"write_projection" |
	"write_fixture" |
	"mutate_source" |
	"run_validation" |
	"collect_evidence" |
	"inspect_git" |
	"stage" |
	"commit"

#WorkerStopCondition:
	"objective_complete" |
	"command_budget_exhausted" |
	"scope_violation" |
	"validation_failed" |
	"permission_required" |
	"blocked"

#WorkerResultStatus: "pass" | "fail" | "blocked" | "stopped"

#WorkerNextAction:
	"merge_evidence" |
	"retry" |
	"revise_scope" |
	"request_permission" |
	"stop"

#WorkerPathScope: close({
	allowedPaths: [string & !="" & !~"^/", ...string & !="" & !~"^/"]
	deniedPaths: [...string & !="" & !~"^/"]
})

#WorkerInputArtifact: close({
	id:    #RuntimeID
	kind:  "contract" | "fixture" | "patch" | "route-result" | "command-output"
	path?: string & !="" & !~"^/"
	ref?:  string & !=""
})

#WorkerCommandBudget: close({
	maxCommands: int & >0
	allowedCommands: [string & !="", ...string & !=""]
})

#WorkerExpectedResult: close({
	schema: "agent.worker-result.v1"
	allowedStatuses: [#WorkerResultStatus, ...#WorkerResultStatus]
	requireValidationEvidence: bool
	maxChangedPaths:           int & >=0
})

#WorkerPermissions: close({
	commit: bool
})

#WorkerPolicy: close({
	runtimeWorkerID: #RuntimeID
	allowedActions: [#WorkerAction, ...#WorkerAction]
})

#WorkerPolicies: {
	"projection-worker": {
		runtimeWorkerID: "codex-route-validator"
		allowedActions: ["inspect", "write_projection", "run_validation", "collect_evidence"]
	}
	"fixture-worker": {
		runtimeWorkerID: "codex-route-validator"
		allowedActions: ["inspect", "write_fixture", "run_validation", "collect_evidence"]
	}
	"validation-worker": {
		runtimeWorkerID: "codex-route-validator"
		allowedActions: ["inspect", "run_validation", "collect_evidence"]
	}
	"git-worker": {
		runtimeWorkerID: "codex-route-inspector"
		allowedActions: ["inspect_git", "stage", "commit", "collect_evidence"]
	}
}

#WorkerRequest: close({
	schema:    "agent.worker-request.v1"
	requestID: #RuntimeID
	invocation: {...}
	_validatedInvocation: #RuntimeInvocation & invocation

	worker:    #SDKWorkerKind
	objective: string & !=""
	pathScope: #WorkerPathScope
	inputArtifacts: [...#WorkerInputArtifact]
	actions: [#WorkerAction, ...#WorkerAction]
	commandBudget: #WorkerCommandBudget
	commands: [...string & !=""]
	stopConditions: [#WorkerStopCondition, ...#WorkerStopCondition]
	expectedResult: #WorkerExpectedResult
	permissions:    #WorkerPermissions
	rootAuthority: close({
		planning:    "root_agent"
		merge:       "root_agent"
		retry:       "root_agent"
		scopeChange: "root_agent"
		finalCommit: "root_agent"
	})
	resultSemantics: "evidence_only"
}) & {
	invocation: {...}
	worker: #SDKWorkerKind
	actions: [#WorkerAction, ...#WorkerAction]
	commandBudget: #WorkerCommandBudget
	commands: [...string & !=""]
	permissions: #WorkerPermissions

	_workerPolicy: #WorkerPolicy & #WorkerPolicies[worker]
	invocation: workerID: _workerPolicy.runtimeWorkerID

	if len(commands) > commandBudget.maxCommands {
		_commandBudgetExceeded: _|_
	}
	for command in commands {
		if !list.Contains(commandBudget.allowedCommands, command) {
			_undeclaredCommand: _|_
		}
	}
	for action in actions {
		if !list.Contains(_workerPolicy.allowedActions, action) {
			_workerActionDenied: _|_
		}
		if action == "commit" {
			permissions: commit: true
		}
	}
}

#WorkerValidationEvidence: close({
	command: string & !=""
	status:  "pass" | "fail" | "blocked"
	summary: string & !=""
})

#WorkerFailure: close({
	class:  "scope" | "permission" | "validation" | "command" | "contract" | "runtime"
	code:   #RuntimeID
	detail: string & !=""
})

#WorkerResult: close({
	request: {...}
	_validatedRequest: #WorkerRequest & request

	schema:    "agent.worker-result.v1"
	requestID: request.requestID
	worker:    request.worker
	status:    #WorkerResultStatus
	summary:   string & !=""
	changedPaths: [...string & !="" & !~"^/"]
	validationEvidence: [...#WorkerValidationEvidence]
	failures: [...#WorkerFailure]
	stopReason: #WorkerStopCondition
	nextAction: #WorkerNextAction
	authority:  "evidence_only"
	returnToRoot: close({
		planningAuthority:    "root_agent"
		mergeAuthority:       "root_agent"
		retryAuthority:       "root_agent"
		scopeChangeAuthority: "root_agent"
		finalCommitAuthority: "root_agent"
	})
}) & {
	request: {...}
	status: #WorkerResultStatus
	changedPaths: [...string & !="" & !~"^/"]
	validationEvidence: [...#WorkerValidationEvidence]

	if !list.Contains(request.expectedResult.allowedStatuses, status) {
		_unexpectedResultStatus: _|_
	}
	if len(changedPaths) > request.expectedResult.maxChangedPaths {
		_changedPathBudgetExceeded: _|_
	}
	if request.expectedResult.requireValidationEvidence && len(validationEvidence) == 0 {
		_validationEvidenceRequired: _|_
	}
	for path in changedPaths {
		if !list.Contains(request.pathScope.allowedPaths, path) {
			_changedPathNotAllowed: _|_
		}
		if list.Contains(request.pathScope.deniedPaths, path) {
			_changedPathDenied: _|_
		}
	}
	if request.worker == "validation-worker" && len(changedPaths) > 0 {
		_validationWorkerChangedPaths: _|_
	}
}
