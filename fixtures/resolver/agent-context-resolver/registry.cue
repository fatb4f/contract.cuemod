package agentcontextresolver

import "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver:agentcontextresolver"

registry: agentcontextresolver.#Registry & {
	fragments: [
		{id: "fragment-workspace-lifecycle", surface: "turn_start", channel: "message", itemKind: "message", expectedNativeContextInjection: true, label: "workspace lifecycle fragment"},
		{id: "fragment-desktop-session", surface: "turn_start", channel: "message", itemKind: "message", expectedNativeContextInjection: true, label: "desktop session fragment"},
	]
}

classification: agentcontextresolver.#PromptClassification & {
	selectedFragments: ["fragment-workspace-lifecycle"]
	hints: {
		domain:        "workspace"
		workflow:      "sessionizer"
		authorityRoot: "contracts/agent-context-resolver"
	}
	evidence: {
		matchedRules: ["turn_start_fragment", "known_fragment"]
		rejectedRules: ["mcp_tool_output", "assembled_context_body"]
	}
}

turnStart: agentcontextresolver.#TurnStartContextFragmentSet & {
	fragments: registry.fragments
}

output: agentcontextresolver.#ResolverOutput & {
	prompt: "How does the WezTerm sessionizer switch workspaces?"
	report: {
		schema:       "agent.context-resolver.lifecycle-report.v1"
		turnStart:    turnStart
		classification: classification
		assertions: [
			{name: "turn_start_available", passed: true},
			{name: "known_fragment_selected", passed: true},
			{name: "context_body_not_assembled", passed: true},
		]
	}
	hook: {
		hook_event_name: "UserPromptSubmit"
		additionalContext: "Agent context lifecycle report: selected fragment IDs only"
	}
}
