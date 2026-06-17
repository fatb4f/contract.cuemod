package validation

import (
	"github.com/fatb4f/contract.cuemod/contracts/graph"
	"github.com/fatb4f/contract.cuemod/contracts/protocols/mcp"
)

#CompleteResult: mcp.#MCPResult & {
	claim: complete: true
	evidence: graph.#Evidence
}

#NegativeClaimResult: #CompleteResult & {
	claim: negative_claim_allowed: true
	capability: "references" | "diagnostics" | "validate"
}

#ProviderMediatedArtifact: graph.#ArtifactAccess & {
	access: direct: false
}
