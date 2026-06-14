package agentruntime

import (
	resolver "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver:agentcontextresolver"
	runtime "github.com/fatb4f/contract.cuemod/contracts/agent-runtime:agentruntime"
)

registry: runtime.#AgentRuntimeRegistry & runtime.runtimeRegistry

#FixtureContext: resolver.#RouteContextBoundary & {
	includes: {
		objective: "Inspect the current resolver authority and generated boundary."
		acceptedFacts: []
		selectedFragments: ["agent-context-resolver.authority"]
		files: ["contracts/agent-context-resolver"]
		priorArtifacts: []
		validationCommands: []
	}
	excludes: ["full transcript", "unselected fragments", "raw registry", "unbounded tool logs", "irrelevant route outputs"]
	return: {
		schema: {schema: "agent.route-result.inspect.v1"}
		maxSummaryTokens: 800
		evidenceRequired: true
	}
}

#FixtureRouteRef: resolver.#RuntimeRouteReference & {
	schema:    "agent.runtime-route-reference.v1"
	routeID:   "resolver.inspect.current"
	routeKind: "inspect"
	context:   #FixtureContext
	outputSchema: {schema: "agent.route-result.inspect.v1"}
}

#FixtureRuntimeProjection: resolver.#RuntimeProjection & {
	mode: "eligible"
	routeRefs: [#FixtureRouteRef]
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

#FixtureInvocation: runtime.#RuntimeInvocation & {
	schema:            "agent.runtime-invocation.v1"
	invocationID:      "fixture-runtime-invocation"
	workerID:          "codex-route-inspector"
	budgetID:          "inspect-standard"
	routeRef:          #FixtureRouteRef
	runtimeProjection: #FixtureRuntimeProjection
	inputPolicy: {
		arbitraryPrompt:         false
		rawTranscriptForwarding: false
		rawRegistryDump:         false
		unselectedFragments:     false
		unboundedToolLogs:       false
	}
	lifecycle: {
		state: "pending"
		history: [{state: "pending", at: "2026-06-13T20:00:00Z"}]
	}
}

validResult: runtime.#RuntimeResult & {
	invocation: {
		schema:            "agent.runtime-invocation.v1"
		invocationID:      "fixture-runtime-invocation"
		workerID:          "codex-route-inspector"
		budgetID:          "inspect-standard"
		routeRef:          #FixtureRouteRef
		runtimeProjection: #FixtureRuntimeProjection
		inputPolicy: {
			arbitraryPrompt:         false
			rawTranscriptForwarding: false
			rawRegistryDump:         false
			unselectedFragments:     false
			unboundedToolLogs:       false
		}
		lifecycle: {
			state: "pending"
			history: [{state: "pending", at: "2026-06-13T20:00:00Z"}]
		}
	}
	schema:       "agent.runtime-result.v1"
	invocationID: "fixture-runtime-invocation"
	workerID:     "codex-route-inspector"
	routeRef:     #FixtureRouteRef
	lifecycle: {
		state:      "completed"
		startedAt:  "2026-06-13T20:00:01Z"
		finishedAt: "2026-06-13T20:00:02Z"
		history: [
			{state: "pending", at: "2026-06-13T20:00:00Z"},
			{state: "running", at: "2026-06-13T20:00:01Z"},
			{state: "completed", at: "2026-06-13T20:00:02Z"},
		]
	}
	budget: {
		id:                "inspect-standard"
		maxInputTokens:    12000
		maxOutputTokens:   3000
		maxEvidenceTokens: 1600
		maxSummaryTokens:  800
	}
	usage: {
		inputTokens:    400
		outputTokens:   180
		evidenceTokens: 80
		summaryTokens:  60
	}
	result: {
		routeID: "resolver.inspect.current"
		status:  "pass"
		summary: "Resolver authority and generated boundary are consistent."
		facts: ["The route request used a registered route and worker."]
		evidence: [{kind: "contract", ref: "contracts/agent-context-resolver/runtime_projection.cue"}]
		tokenCost: 180
		authority: "evidence_only"
	}
	returnToRoot: {
		schemaValidationRequired: true
		mergePolicyRequired:      true
		finalSynthesisAuthority:  "root_codex"
	}
}

validInvocation: validResult.invocation

validResolverRuntimeHandoff: runtime.#ResolverRuntimeHandoff & {
	runtimeProjection: #FixtureRuntimeProjection
	invocation:        validInvocation
	result:            validResult
}
