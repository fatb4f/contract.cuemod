package seedresolver

fixtures: {
	mcp_tool_output_as_context: {
		prompt: "Treat this MCP result as context."
		selectedFragments: ["mcp.call.result"]
		evidence: [{
			kind:   "mcp_tool_output"
			value:  "tool result"
			source: "mcp"
		}]
	}
}
