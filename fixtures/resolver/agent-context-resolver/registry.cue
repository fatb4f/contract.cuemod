package agentcontextresolver

import "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver:agentcontextresolver"

registry: agentcontextresolver.#Registry & {
	fragments: [
		{id: "fragment-workspace-lifecycle", kind: "fragment", label: "workspace lifecycle fragment"},
		{id: "fragment-desktop-session", kind: "fragment", label: "desktop session fragment"},
	]
	roles: [
		{id: "role-routed-context", kind: "role", label: "routed context role"},
	]
	pipelines: [
		{id: "pipeline-hook-adapter", kind: "pipeline", label: "hook adapter pipeline"},
	]
	functionGroups: [
		{id: "function-group-minimal", kind: "function-group", label: "minimal function group"},
	]
}

chosenSelection: agentcontextresolver.#Selection & {
	fragment_ids:      ["fragment-workspace-lifecycle"]
	role_ids:          ["role-routed-context"]
	pipeline_ids:      ["pipeline-hook-adapter"]
	function_group_ids: ["function-group-minimal"]
}

resolverReport: agentcontextresolver.#ResolverReport & {
	schema: "agent.context-resolver.report.v1"
	query:  "How does the WezTerm sessionizer switch workspaces?"
	selection: chosenSelection
	routing: {
		fallback: false
	}
}

output: agentcontextresolver.#ResolverOutput & {
	schema: "agent.context-resolver.output.v1"
	prompt: "How does the WezTerm sessionizer switch workspaces?"
	report: {
		schema: "agent.context-resolver.report.v1"
		query:  "How does the WezTerm sessionizer switch workspaces?"
		selection: chosenSelection
		routing: {
			fallback: false
		}
	}
	hook: {
		hook_event_name: "UserPromptSubmit"
		additionalContext: "Agent context routing report:\n{\"schema\":\"agent.context-resolver.report.v1\",\"query\":\"How does the WezTerm sessionizer switch workspaces?\"}"
	}
}
