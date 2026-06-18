package valid

import "github.com/fatb4f/contract.cuemod/contracts/providers"

cueDefinition: providers.#CueLSPResult & {
	provider_id:   "df:provider/cue-lsp-mcp"
	projection_id: "df:projection/stage3-mcp-authority"
	contract_id:   "df:contract/mcp-provider-authority"
	provider: {
		id:        "df:provider/cue-lsp-mcp"
		kind:      "cue-lsp"
		authority: "cue-graph"
		protocol:  "lsp-over-mcp"
	}
	capability: "definition"
	claim: kind: "definition"
}

luaSymbolEvidence: providers.#LuaEvidenceResult & {
	provider_id:       "df:provider/lua-lsp-mcp"
	projection_id:     "df:projection/stage3-mcp-authority"
	implementation_id: "df:implementation/wezterm-smart-splits"
	artifact_id:       "df:artifact/wezterm-smart-splits-lua"
	symbol_id:         "df:symbol/wezterm-smart-splits-apply-to-config"
	evidence_id:       "df:evidence/wezterm-smart-splits-apply-to-config"
	provider: {
		id:        "df:provider/lua-lsp-mcp"
		kind:      "lua-lsp"
		authority: "lua-implementation"
		protocol:  "lsp-over-mcp"
	}
	capability: "evidence"
	claim: {
		kind:     "symbol-evidence"
		complete: true
	}
	evidence: {
		evidence_id: "df:evidence/wezterm-smart-splits-apply-to-config"
		provider_id: "df:provider/lua-lsp-mcp"
		artifact_id: "df:artifact/wezterm-smart-splits-lua"
		symbol_id:   "df:symbol/wezterm-smart-splits-apply-to-config"
		summary:     "Lua LSP resolves the typed apply_to_config symbol."
	}
}
