package mcpprojection

import (
	resolver "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver:agentcontextresolver"
	mcp "github.com/fatb4f/contract.cuemod/contracts/protocols/mcp"
)

domain: {
	id:          "agent-context-resolver/projections/mcp"
	kind:        "projection"
	authority:   false
	extractable:  false
	imports:     ["agent-context-resolver", "protocols/mcp"]
}

#ResolverMCPTool: close({
	name: "acr.inventory" | "acr.resolve_prompt" | "acr.plan_route" | "acr.validate" | "acr.export_runtime_projection"
	routeID: resolver.#DeclaredID
	result?: mcp.#MCPResult
})
