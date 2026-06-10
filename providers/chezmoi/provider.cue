package chezmoi

import "github.com/fatb4f/contract.cuemod/contracts/providers"

// Identity-only stub. Deployment completeness is intentionally deferred.
provider: providers.#TypedProvider & {
	id:        "df:provider/chezmoi-mcp"
	kind:      "chezmoi"
	protocol:  "mcp-tool"
	authority: "deployment-provenance"
	capabilities: []
}
