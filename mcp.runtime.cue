package workspace

import (
	"github.com/fatb4f/contract.cuemod/contracts/mcp"
	"github.com/fatb4f/contract.cuemod/contracts/providers"
)

#CueMCPResult: mcp.#MCPResult & {
	provider_id: "df:provider/cue-lsp-mcp"
	provider: {
		id:        "df:provider/cue-lsp-mcp"
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

#ProjectionLookupErrorMCPResult: #CueMCPResult & {
	capability: "definition"
	claim: {
		kind:                   "projection-lookup-error"
		complete:               false
		negative_claim_allowed: false
	}
	result: #SearchImplementationError
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

#ValidateProjectionErrorMCPResult: #CueMCPResult & {
	capability: "validate"
	claim: {
		kind:                   "projection-validation-error"
		complete:               false
		negative_claim_allowed: false
	}
	result: #SearchImplementationError
}

#SearchImplementationMCPResult: mcp.#MCPResult & {
	provider_id: "df:provider/cue-rg-mcp"
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
	result: #SearchImplementationResponse
}

#SearchImplementationErrorMCPResult: mcp.#MCPResult & {
	provider_id: "df:provider/cue-rg-mcp"
	provider: {
		id:        "df:provider/cue-rg-mcp"
		kind:      "cue-rg"
		protocol:  "mcp-tool"
		authority: "bounded-text-evidence"
	}
	capability: "search"
	claim: {
		kind:                   "search-error"
		complete:               false
		negative_claim_allowed: false
	}
	result: #SearchImplementationError
}

#TypedProviderFixture: providers.#TypedProvider
