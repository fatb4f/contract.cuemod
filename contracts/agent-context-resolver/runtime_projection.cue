package agentcontextresolver

#RuntimeProjection: close({
	mode: "none" | "eligible" | "requires-agent-runtime"

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
