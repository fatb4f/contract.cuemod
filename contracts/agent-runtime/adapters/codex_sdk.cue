package agentruntimeadapters

#CodexSDKBackend: close({
	id:        "codex-sdk-hidden"
	kind:      "codex-sdk"
	exposure:  "hidden-backend"
	authority: "execution-backend-only"

	invocation: close({
		throughAdapterID:   "mcp-route-executor"
		directFromResolver: false
		directFromRoot:     false
		arbitraryPrompt:    false
	})

	lifecycleOwnedByRuntime:  true
	resultsReturnThroughMCP:  true
	liveExecutionImplemented: false
})

codexSDKBackend: #CodexSDKBackend & {
	id:        "codex-sdk-hidden"
	kind:      "codex-sdk"
	exposure:  "hidden-backend"
	authority: "execution-backend-only"
	invocation: {
		throughAdapterID:   "mcp-route-executor"
		directFromResolver: false
		directFromRoot:     false
		arbitraryPrompt:    false
	}
	lifecycleOwnedByRuntime:  true
	resultsReturnThroughMCP:  true
	liveExecutionImplemented: false
}
