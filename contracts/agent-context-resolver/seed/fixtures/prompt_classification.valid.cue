package seedresolver

fixtures: {
	prompt_classification: {
		prompt: "Update the resolver hook without allowing MCP tool output to become context."
		expectedSelectedFragments: [
			"agent-context-resolver.authority",
			"mcp.evidence-plane",
			"agent-skill.projection",
		]
	}
}
