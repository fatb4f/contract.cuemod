package invalidmcptooloutput

import "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver:agentcontextresolver"

registry: agentcontextresolver.#Registry & {
	fragments: [
		{id: "fragment-workspace-lifecycle", surface: "turn_start", channel: "message", itemKind: "message", expectedNativeContextInjection: true, label: "workspace lifecycle fragment"},
		{id: "fragment-runtime-tool-output", surface: "mcp", channel: "resource", itemKind: "tool_output", expectedNativeContextInjection: true, label: "runtime tool output fragment"},
	]
}

classification: agentcontextresolver.#PromptClassification & {
	selectedFragments: ["fragment-runtime-tool-output"]
	hints: {
		domain:        "workspace"
		workflow:      "sessionizer"
		authorityRoot: "contracts/agent-context-resolver"
	}
	evidence: {
		matchedRules: ["tool_output"]
	}
}

turnStart: agentcontextresolver.#TurnStartContextFragmentSet & {
	fragments: [registry.fragments[0]]
}

output: agentcontextresolver.#ResolverOutput & {
	prompt: "How does the WezTerm sessionizer switch workspaces?"
	report: {
		schema:       "agent.context-resolver.lifecycle-report.v1"
		registry:     registry
		turnStart:    turnStart
		classification: classification
		assertions: [
			{name: "turn_start_available", passed: true},
		]
	}
	hook: {
		hook_event_name: "UserPromptSubmit"
		selectedFragments: classification.selectedFragments
		hints:             classification.hints
		evidence:          classification.evidence
		additionalContext:  "Agent context lifecycle report: selected fragment IDs only"
	}
}
