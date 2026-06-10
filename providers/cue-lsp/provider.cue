package cuelsp

import "github.com/fatb4f/contract.cuemod/contracts/providers"

provider: providers.#TypedProvider & {
	id:        "df:provider/cue-lsp-mcp"
	kind:      "cue-lsp"
	protocol:  "lsp-over-mcp"
	authority: "cue-graph"
	capabilities: [
		"definition",
		"references",
		"hover",
		"diagnostics",
		"documentSymbols",
		"workspaceSymbols",
		"validate",
	]
}

semanticOwnership: [
	"contract-definitions",
	"references",
	"constraints",
	"diagnostics",
	"schema-completeness",
]
