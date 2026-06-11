package invalidadapteroutput

import "github.com/fatb4f/contract.cuemod/contracts/mcp"

result: mcp.#MCPResult & {
	provider_id: "df:provider/cue-rg-mcp"
	provider: {
		kind:      "unbound-provider-kind"
		protocol:  "mcp-tool"
		authority: "bounded-text-evidence"
	}
	capability: "search"
	claim: {
		kind: "bounded-text-evidence"
	}
}
