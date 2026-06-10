package stage3

import (
	"github.com/fatb4f/contract.cuemod/contracts/graph"
	cuelsp "github.com/fatb4f/contract.cuemod/providers/cue-lsp:cuelsp"
	lualsp "github.com/fatb4f/contract.cuemod/providers/lua-lsp:lualsp"
)

#Stage3Projection: close({
	projection_id: "df:projection/stage3-mcp-authority"
	provider_ids: [
		"df:provider/cue-lsp-mcp",
		"df:provider/lua-lsp-mcp",
	]
	contract_ids: [...graph.#ContractID]
	artifact_ids: [...graph.#ArtifactID]
	evidence_ids: [...graph.#EvidenceID]
})

projection: #Stage3Projection & {
	contract_ids: ["df:contract/mcp-provider-authority"]
	artifact_ids: []
	evidence_ids: []
}

providers: [
	cuelsp.provider,
	lualsp.provider,
]
