package assertions

mcpProjectionAssertions: {
	projection: {
		id:          "agent-context-resolver/projections/mcp"
		kind:        "projection"
		authority:   false
		extractable: false
		imports: ["agent-context-resolver", "protocols/mcp"]
	}

	adapterAuthority: false
}
