package mcpserveradapter

import adapters "github.com/fatb4f/contract.cuemod/contracts/adapters"

boundary: adapters.#AdapterBoundary & {
	id:   "agent-context-resolver.adapters.mcp-server"
	kind: "mcp-server"
}
