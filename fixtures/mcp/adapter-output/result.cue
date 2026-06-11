package adapteroutput

import "github.com/fatb4f/contract.cuemod/contracts/mcp"

result: mcp.#MCPResult & {
	provider_id: "df:provider/cue-rg-mcp"
	contract_id: "df:contract/mcp-provider-authority"
	provider: {
		id:        "df:provider/cue-rg-mcp"
		kind:      "cue-rg"
		protocol:  "mcp-tool"
		authority: "bounded-text-evidence"
	}
	capability: "search"
	claim: {
		kind:                   "bounded-text-evidence"
		complete:               false
		negative_claim_allowed: false
	}
	result: {
		schema: "agent.search-implementation.response.v1"
	}
}
