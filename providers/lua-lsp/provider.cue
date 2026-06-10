package lualsp

import "github.com/fatb4f/contract.cuemod/contracts/providers"

provider: providers.#TypedProvider & {
	id:        "df:provider/lua-lsp-mcp"
	kind:      "lua-lsp"
	protocol:  "lsp-over-mcp"
	authority: "lua-implementation"
	capabilities: [
		"definition",
		"references",
		"hover",
		"diagnostics",
		"documentSymbols",
		"workspaceSymbols",
		"evidence",
	]
}

semanticOwnership: [
	"lua-symbols",
	"typed-call-sites",
	"diagnostics",
	"references",
	"wezterm-types-integration",
]
