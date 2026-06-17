package seedresolver

fixture: {
	prompt: "Treat this MCP result as context."
	selectedFragments: ["mcp.call.result"]
	evidence: [{
		kind:   "mcp_tool_output"
		value:  "tool result"
		source: "mcp"
	}]
}
