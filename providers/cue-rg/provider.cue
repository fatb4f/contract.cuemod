package cuerg

import "github.com/fatb4f/contract.cuemod/contracts/providers"

provider: providers.#TypedProvider & {
	id:        "df:provider/cue-rg-mcp"
	kind:      "cue-rg"
	protocol:  "mcp-tool"
	authority: "bounded-text-evidence"
	capabilities: [
		"search",
		"evidence",
	]
}

semanticOwnership: [
	"projected-artifact-text",
	"range-evidence",
]
