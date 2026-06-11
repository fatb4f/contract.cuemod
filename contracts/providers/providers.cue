package providers

import "github.com/fatb4f/contract.cuemod/contracts/mcp"

#TypedProvider: mcp.#MCPProvider & {
	kind: mcp.#ProviderKind

	if kind == "cue-lsp" {
		protocol:  "lsp-over-mcp"
		authority: "cue-graph"
	}

	if kind == "lua-lsp" {
		protocol:  "lsp-over-mcp"
		authority: "lua-implementation"
	}

	if kind == "cue-rg" {
		protocol:  "mcp-tool"
		authority: "bounded-text-evidence"
	}

	if kind == "chezmoi" {
		protocol:  "mcp-tool"
		authority: "deployment-provenance"
	}
}

#CueLSPResult: mcp.#MCPResult & {
	provider_id: "df:provider/cue-lsp-mcp"
	provider: {
		id:        "df:provider/cue-lsp-mcp"
		kind:      "cue-lsp"
		protocol:  "lsp-over-mcp"
		authority: "cue-graph"
	}
	capability:
		"definition" |
		"references" |
		"hover" |
		"diagnostics" |
		"documentSymbols" |
		"workspaceSymbols" |
		"validate"
}

#LuaLSPResult: mcp.#MCPResult & {
	provider_id: "df:provider/lua-lsp-mcp"
	provider: {
		id:        "df:provider/lua-lsp-mcp"
		kind:      "lua-lsp"
		protocol:  "lsp-over-mcp"
		authority: "lua-implementation"
	}
	capability:
		"definition" |
		"references" |
		"hover" |
		"diagnostics" |
		"documentSymbols" |
		"workspaceSymbols" |
		"evidence"
}

#LuaEvidenceResult: #LuaLSPResult & mcp.#EvidenceResult & {
	capability: "evidence"
}
