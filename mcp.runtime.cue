package workspace

import (
	"github.com/fatb4f/contract.cuemod/contracts/mcp"
	"github.com/fatb4f/contract.cuemod/contracts/providers"
)

#CueMCPResult: mcp.#MCPResult & {
	provider_id: "df:provider/cue-lsp-mcp"
	provider: {
		kind:      "cue-lsp"
		protocol:  "lsp-over-mcp"
		authority: "cue-graph"
	}
}

#ResolveAgentContextMCPResult: #CueMCPResult & {
	capability: "validate"
	claim: {
		kind:                   "context-projection"
		complete:               false
		negative_claim_allowed: false
	}
	result: #ResolveAgentContextResponse
}

#ProjectionLookupMCPResult: #CueMCPResult & {
	capability: "definition"
	claim: {
		kind:                   "projection-lookup"
		complete:               false
		negative_claim_allowed: false
	}
	result: #ProjectionLookupResponse
}

#SemanticProvidersMCPResult: #CueMCPResult & {
	capability: "definition"
	claim: {
		kind:                   "provider-catalog"
		complete:               false
		negative_claim_allowed: false
	}
	result: #SemanticProvidersResponse
}

#ValidateProjectionMCPResult: #CueMCPResult & {
	capability: "validate"
	claim: {
		kind:                   "projection-validation"
		complete:               false
		negative_claim_allowed: false
	}
	result: #ValidateProjectionResponse
}

#SearchImplementationMCPResult: mcp.#MCPResult & {
	provider_id: "df:provider/cue-rg-mcp"
	provider: {
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
	result: #SearchImplementationResponse
}

#TypedProviderFixture: providers.#TypedProvider
