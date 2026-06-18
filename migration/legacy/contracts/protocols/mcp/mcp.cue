package mcp

import "github.com/fatb4f/contract.cuemod/contracts/graph"

#ProviderKind: "cue-lsp" | "lua-lsp" | "cue-rg" | "chezmoi"

#AuthorityPlane:
	"cue-graph" |
	"lua-implementation" |
	"bounded-text-evidence" |
	"deployment-provenance"

#MCPCapability:
	"definition" |
	"references" |
	"hover" |
	"diagnostics" |
	"documentSymbols" |
	"workspaceSymbols" |
	"search" |
	"validate" |
	"evidence"

#MCPProvider: close({
	id:       graph.#ProviderID
	kind:     #ProviderKind
	protocol: "lsp-over-mcp" | "mcp-tool"
	capabilities: [...#MCPCapability]
	authority: #AuthorityPlane
})

#Diagnostic: close({
	code?:    string & !=""
	severity: "error" | "warning" | "information" | "hint"
	message:  string & !=""
})

#MCPResult: close({
	provider_id:    graph.#ProviderID
	projection_id?: graph.#ProjectionID
	let resultProviderID = provider_id

	contract_id?:       graph.#ContractID
	node_id?:           graph.#NodeID
	implementation_id?: graph.#ImplementationID
	artifact_id?:       graph.#ArtifactID
	symbol_id?:         graph.#SymbolID
	evidence_id?:       graph.#EvidenceID

	provider: close({
		id:        resultProviderID
		kind:      #ProviderKind
		authority: #AuthorityPlane
		protocol:  "lsp-over-mcp" | "mcp-tool"
	})

	capability: #MCPCapability

	claim: close({
		kind:                   string & !=""
		complete:               bool | *false
		negative_claim_allowed: bool | *false
	})

	evidence?: graph.#Evidence & {
		provider_id: resultProviderID
	}
	diagnostics?: [...#Diagnostic]

	if claim.complete {
		evidence: graph.#Evidence
	}

	if claim.negative_claim_allowed {
		claim: complete: true
		capability: "references" | "diagnostics" | "validate"
		evidence:   graph.#Evidence
	}

	result?: _
})

#EvidenceResult: #MCPResult & {
	evidence:    graph.#Evidence
	evidence_id: evidence.evidence_id
	artifact_id: evidence.artifact_id
}
