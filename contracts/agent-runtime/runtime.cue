package agentruntime

#WorkerRuntimeAdapter:
	"a2a" |
	"sdk-direct" |
	"mcp" |
	"cli"

#RouteContextBoundary: close({
	includes: [...string]
	excludes: [...string]
})

#RouteOutputSchema:
	"agent.route-result.v1" |
	"agent.route-inventory.v1" |
	"agent.validation-certificate.v1"

#RuntimeRouteReference: close({
	schema:       "agent.runtime-route-reference.v1"
	routeID:      #RuntimeID
	routeKind:    #RouteKind
	context:      #RouteContextBoundary
	outputSchema: #RouteOutputSchema
})

#RuntimeRouteResult: close({
	schema:  "agent.route-result.v1"
	routeID: #RuntimeID
	status:  "ok" | "failed" | "blocked"
	evidence?: [...#RuntimeEvidence]
})

#RuntimeProjection: close({
	mode: "none" | "eligible" | "requires-agent-runtime"
	routeRefs: [...#RuntimeRouteReference]

	requirements: close({
		agentRuntimeRegistry:  "absent" | "present"
		workerAdapterRegistry: "absent" | "present" | *"absent"
		mcpRouteExecutor:      "absent" | "present"
	})

	execution: close({
		allowed:                bool
		preferredWorkerAdapter: "a2a" | *"a2a"
		secondaryWorkerAdapters: [...#WorkerRuntimeAdapter] | *["sdk-direct", "mcp", "cli"]
		requiresA2AAdapter:      bool | *true
		requiresMCPAdapter:      bool | *false
		requiresRuntimeRegistry: bool | *true
		backend:                 "none" | "codex-sdk" | "a2a"
	})

	deny: close({
		directSDKSpawn:          true
		rawTranscriptForwarding: true
		rawRegistryDump:         true
		unselectedFragments:     true
		globalMutation:          true
		authorityDelegation:     true
		freeFormMCPToolExposure: true
	})

	expectedResult: close({
		schema: "agent.route-result.v1"
	})
})
