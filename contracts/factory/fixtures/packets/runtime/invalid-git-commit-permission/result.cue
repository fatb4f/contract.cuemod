package invalidgitcommitpermission

import (
	runtime "github.com/fatb4f/contract.cuemod/contracts/agent-runtime:agentruntime"
	fixtures "github.com/fatb4f/contract.cuemod/fixtures/agent-runtime:agentruntime"
)

invalid: runtime.#WorkerRequest & {
	schema:     "agent.worker-request.v1"
	requestID:  "fixture-git-request"
	invocation: fixtures.#FixtureInvocation
	worker:     "git-worker"
	objective:  "Commit the bounded worker contract changes."
	pathScope: {
		allowedPaths: ["contracts/agent-runtime", "fixtures/agent-runtime", "contracts/agent-runtime/assertions.cue"]
		deniedPaths: ["generated", "projections"]
	}
	inputArtifacts: []
	actions: ["inspect_git", "commit"]
	commandBudget: {
		maxCommands: 2
		allowedCommands: ["git status", "git commit"]
	}
	commands: ["git status", "git commit"]
	stopConditions: ["objective_complete", "permission_required", "scope_violation"]
	expectedResult: {
		schema: "agent.worker-result.v1"
		allowedStatuses: ["pass", "fail", "blocked"]
		requireValidationEvidence: true
		maxChangedPaths:           0
	}
	permissions: commit: false
	rootAuthority: {
		planning:    "root_agent"
		merge:       "root_agent"
		retry:       "root_agent"
		scopeChange: "root_agent"
		finalCommit: "root_agent"
	}
	resultSemantics: "evidence_only"
}
