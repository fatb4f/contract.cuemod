package agentruntimeadapters

#MCPRouteExecutorAdapter: close({
	id:        "mcp-route-executor"
	kind:      "mcp-route-executor"
	protocol:  "mcp-tool"
	exposure:  "runtime-only"
	authority: "agent-runtime-registry"

	accepts: close({
		invocationSchema:      "agent.runtime-invocation.v1"
		registeredRoutesOnly:  true
		registeredWorkersOnly: true
		declaredBudgetsOnly:   true
		routeLocalContextOnly: true
	})

	denies: close({
		arbitraryPrompts:        true
		rawTranscriptForwarding: true
		rawRegistryDumps:        true
		directSDKInvocation:     true
	})

	returns: close({
		resultSchema:       "agent.runtime-result.v1"
		rootMergeAuthority: "root_codex"
	})

	backendAdapterID:         "codex-sdk-hidden"
	liveExecutionImplemented: false
})

mcpRouteExecutor: #MCPRouteExecutorAdapter & {
	id:        "mcp-route-executor"
	kind:      "mcp-route-executor"
	protocol:  "mcp-tool"
	exposure:  "runtime-only"
	authority: "agent-runtime-registry"
	accepts: {
		invocationSchema:      "agent.runtime-invocation.v1"
		registeredRoutesOnly:  true
		registeredWorkersOnly: true
		declaredBudgetsOnly:   true
		routeLocalContextOnly: true
	}
	denies: {
		arbitraryPrompts:        true
		rawTranscriptForwarding: true
		rawRegistryDumps:        true
		directSDKInvocation:     true
	}
	returns: {
		resultSchema:       "agent.runtime-result.v1"
		rootMergeAuthority: "root_codex"
	}
	backendAdapterID:         "codex-sdk-hidden"
	liveExecutionImplemented: false
}
