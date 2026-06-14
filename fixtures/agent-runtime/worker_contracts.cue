package agentruntime

import (
	resolver "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver:agentcontextresolver"
	runtime "github.com/fatb4f/contract.cuemod/contracts/agent-runtime:agentruntime"
)

#WorkerFixtureContext: resolver.#RouteContextBoundary & {
	includes: {
		objective: "Validate bounded worker contracts and fixtures."
		acceptedFacts: []
		selectedFragments: ["agent-runtime.authority"]
		files: ["contracts/agent-runtime", "fixtures/agent-runtime"]
		priorArtifacts: []
		validationCommands: ["cue vet ./contracts/agent-runtime", "cue vet ./fixtures/agent-runtime"]
	}
	excludes: ["full transcript", "unselected fragments", "raw registry", "unbounded tool logs", "irrelevant route outputs"]
	return: {
		schema: {schema: "agent.route-result.validation.v1"}
		maxSummaryTokens: 1000
		evidenceRequired: true
	}
}

#WorkerFixtureRouteRef: resolver.#RuntimeRouteReference & {
	schema:    "agent.runtime-route-reference.v1"
	routeID:   "resolver.plan.compile"
	routeKind: "validate"
	context:   #WorkerFixtureContext
	outputSchema: {schema: "agent.route-result.validation.v1"}
}

#WorkerFixtureProjection: resolver.#RuntimeProjection & {
	mode: "eligible"
	routeRefs: [#WorkerFixtureRouteRef]
	requirements: {
		agentRuntimeRegistry: "present"
		mcpRouteExecutor:     "present"
	}
	execution: {
		allowed:                 true
		requiresMCPAdapter:      true
		requiresRuntimeRegistry: true
		backend:                 "codex-sdk"
	}
	deny: {
		directSDKSpawn:          true
		rawTranscriptForwarding: true
		rawRegistryDump:         true
		unselectedFragments:     true
		globalMutation:          true
	}
	expectedResult: {schema: "agent.route-result.v1"}
}

#WorkerFixtureInvocation: runtime.#RuntimeInvocation & {
	schema:            "agent.runtime-invocation.v1"
	invocationID:      "fixture-worker-invocation"
	workerID:          "codex-route-validator"
	budgetID:          "validate-standard"
	routeRef:          #WorkerFixtureRouteRef
	runtimeProjection: #WorkerFixtureProjection
	inputPolicy: {
		arbitraryPrompt:         false
		rawTranscriptForwarding: false
		rawRegistryDump:         false
		unselectedFragments:     false
		unboundedToolLogs:       false
	}
	lifecycle: {
		state: "pending"
		history: [{state: "pending", at: "2026-06-14T12:00:00Z"}]
	}
}

#ValidWorkerRequest: runtime.#WorkerRequest & {
	schema:     "agent.worker-request.v1"
	requestID:  "fixture-validation-request"
	invocation: #WorkerFixtureInvocation
	worker:     "validation-worker"
	objective:  "Validate the bounded worker contracts and fixtures."
	pathScope: {
		allowedPaths: ["contracts/agent-runtime", "fixtures/agent-runtime"]
		deniedPaths: ["generated", "projections"]
	}
	inputArtifacts: [{
		id:   "worker-contract"
		kind: "contract"
		path: "contracts/agent-runtime/sdk_workers.cue"
	}]
	actions: ["inspect", "run_validation", "collect_evidence"]
	commandBudget: {
		maxCommands: 2
		allowedCommands: ["cue vet ./contracts/agent-runtime", "cue vet ./fixtures/agent-runtime"]
	}
	commands: ["cue vet ./contracts/agent-runtime", "cue vet ./fixtures/agent-runtime"]
	stopConditions: ["objective_complete", "command_budget_exhausted", "validation_failed", "scope_violation"]
	expectedResult: {
		schema: "agent.worker-result.v1"
		allowedStatuses: ["pass", "fail", "blocked"]
		requireValidationEvidence: true
		maxChangedPaths:           0
	}
	permissions: {commit: false}
	rootAuthority: {
		planning:    "root_agent"
		merge:       "root_agent"
		retry:       "root_agent"
		scopeChange: "root_agent"
		finalCommit: "root_agent"
	}
	resultSemantics: "evidence_only"
}

validWorkerRequest: #ValidWorkerRequest

validWorkerResult: runtime.#WorkerResult & {
	request:   #ValidWorkerRequest
	schema:    "agent.worker-result.v1"
	requestID: "fixture-validation-request"
	worker:    "validation-worker"
	status:    "pass"
	summary:   "The bounded worker contracts and fixtures validate."
	changedPaths: []
	validationEvidence: [
		{
			command: "cue vet ./contracts/agent-runtime"
			status:  "pass"
			summary: "The authoritative runtime contracts are valid."
		},
		{
			command: "cue vet ./fixtures/agent-runtime"
			status:  "pass"
			summary: "The positive runtime fixtures are valid."
		},
	]
	failures: []
	stopReason: "objective_complete"
	nextAction: "merge_evidence"
	authority:  "evidence_only"
	returnToRoot: {
		planningAuthority:    "root_agent"
		mergeAuthority:       "root_agent"
		retryAuthority:       "root_agent"
		scopeChangeAuthority: "root_agent"
		finalCommitAuthority: "root_agent"
	}
}
