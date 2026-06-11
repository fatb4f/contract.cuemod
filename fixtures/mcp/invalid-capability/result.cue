package invalidcapability

import "github.com/fatb4f/contract.cuemod/contracts/mcp"

result: mcp.#MCPResult & {
	provider_id: "df:provider/cue-rg-mcp"
	provider: {
		kind:      "cue-rg"
		protocol:  "mcp-tool"
		authority: "bounded-text-evidence"
	}
	capability: "invented-capability"
	claim: kind: "bounded-text-evidence"
}
