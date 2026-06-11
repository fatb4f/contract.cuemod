package invalidnegative

import "github.com/fatb4f/contract.cuemod/contracts/providers"

result: providers.#LuaLSPResult & {
	provider_id: "df:provider/lua-lsp-mcp"
	artifact_id: "df:artifact/wezterm-smart-splits-lua"
	provider: {
		id:        "df:provider/lua-lsp-mcp"
		kind:      "lua-lsp"
		authority: "lua-implementation"
		protocol:  "lsp-over-mcp"
	}
	capability: "hover"
	claim: {
		kind:                   "symbol-absent"
		negative_claim_allowed: true
	}
}
