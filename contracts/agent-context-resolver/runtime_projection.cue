package agentcontextresolver

#RuntimeRouteReference: close({
	schema:       "agent.runtime-route-reference.v1"
	routeID:      #DeclaredID
	routeKind:    #RouteKind
	context:      #RouteContextBoundary
	outputSchema: #RouteOutputSchema
})

#RuntimeProjection: close({
	mode: "none" | "eligible" | "requires-agent-runtime"
	routeRefs: [...#RuntimeRouteReference]

	requirements: close({
		agentRuntimeRegistry: "absent" | "present"
		mcpRouteExecutor:     "absent" | "present"
	})

	execution: close({
		allowed:                 bool
		requiresMCPAdapter:      bool | *true
		requiresRuntimeRegistry: bool | *true
		backend:                 "none" | "codex-sdk"
	})

	deny: close({
		directSDKSpawn:          true
		rawTranscriptForwarding: true
		rawRegistryDump:         true
		unselectedFragments:     true
		globalMutation:          true
	})

	expectedResult: close({
		schema: "agent.route-result.v1"
	})

	if mode == "requires-agent-runtime" {
		execution: allowed: false
	}
	if execution.allowed {
		mode: "eligible"
		routeRefs: [_, ...]
		requirements: {
			agentRuntimeRegistry: "present"
			mcpRouteExecutor:     "present"
		}
		execution: {
			requiresMCPAdapter:      true
			requiresRuntimeRegistry: true
		}
	}
})
