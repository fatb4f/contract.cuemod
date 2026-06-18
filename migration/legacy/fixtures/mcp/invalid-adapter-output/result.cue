package invalidadapteroutput

import "github.com/fatb4f/contract.cuemod/contracts/protocols/mcp"

result: mcp.#MCPResult & {
	provider_id: "df:provider/cue-rg-mcp"
	provider: {
		id:        "df:provider/cue-rg-mcp"
		kind:      "unbound-provider-kind"
		protocol:  "mcp-tool"
		authority: "bounded-text-evidence"
	}
	capability: "search"
	claim: {
		kind: "bounded-text-evidence"
	}
}
