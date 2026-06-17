package agentruntime

#RuntimeBoundary: close({
	id:        "agent-runtime"
	authority: true
	owns: [
		"sessions",
		"turns",
		"messages",
		"tool-calls",
		"native-context",
		"context-window",
		"lifecycle",
	]
	forbiddenImports: ["agent-context-resolver"]
})

runtimeBoundary: #RuntimeBoundary
