package resolver

import "github.com/fatb4f/contract.cuemod/contracts/graph"

#EntityKind:
	"contract" |
	"node" |
	"implementation" |
	"artifact" |
	"symbol" |
	"evidence"

#DependencyPredicate:
	"requires" |
	"implemented_by" |
	"stored_in" |
	"defines_symbol" |
	"evidenced_by" |
	"validated_by"

#Entity: {
	id:           graph.#EntityID
	kind:         #EntityKind
	name:         string & !=""
	raw_path?:    string & !="" & !~"^/"
	symbol?:      string & !=""
	provider_id?: graph.#ProviderID
	range?: close({
		start: close({
			line:      int & >=1
			character: int & >=1
		})
		end: close({
			line:      int & >=1
			character: int & >=1
		})
	})

	if kind == "contract" {
		id: graph.#ContractID
	}
	if kind == "node" {
		id: graph.#NodeID
	}
	if kind == "implementation" {
		id: graph.#ImplementationID
	}
	if kind == "artifact" {
		id: graph.#ArtifactID
	}
	if kind == "symbol" {
		id: graph.#SymbolID
	}
	if kind == "evidence" {
		id: graph.#EvidenceID
	}
}

#Edge: close({
	id:        graph.#EdgeID
	predicate: #DependencyPredicate
	source:    graph.#EntityID
	target:    graph.#EntityID

	if predicate == "requires" {
		source: graph.#ContractID | graph.#NodeID
		target: graph.#NodeID
	}
	if predicate == "implemented_by" {
		source: graph.#NodeID
		target: graph.#ImplementationID
	}
	if predicate == "stored_in" {
		source: graph.#ImplementationID
		target: graph.#ArtifactID
	}
	if predicate == "defines_symbol" {
		source: graph.#ImplementationID
		target: graph.#SymbolID
	}
	if predicate == "evidenced_by" {
		source: graph.#SymbolID | graph.#ArtifactID
		target: graph.#EvidenceID
	}
	if predicate == "validated_by" {
		source: graph.#ContractID | graph.#NodeID | graph.#ImplementationID
		target: graph.#EvidenceID
	}
})

#InclusionReason: close({
	edge_id:   graph.#EdgeID
	predicate: #DependencyPredicate
	source:    graph.#EntityID
	target:    graph.#EntityID
})

#ProjectedEntity: {
	#Entity
	included_because: [#InclusionReason, ...#InclusionReason]
}

#ProviderRoute: close({
	entity_id:   graph.#EntityID
	provider_id: graph.#ProviderID
	purpose:     "graph-definition" | "symbol-evidence" | "text-verification"
})

#Exclusion: close({
	entity_id: graph.#EntityID
	reason:    "no-explicit-edge" | "outside-projection" | "provider-denied"
})

#Completeness: close({
	complete: bool
	missing_nodes: [...graph.#NodeID]
	missing_edges: [...graph.#EdgeID]
	missing_implementations: [...graph.#ImplementationID]
	missing_artifacts: [...graph.#ArtifactID]
	missing_symbols: [...graph.#SymbolID]
	missing_evidence: [...graph.#EvidenceID]
	failed_validations: [...graph.#ValidationID]

	if complete {
		missing_nodes: []
		missing_edges: []
		missing_implementations: []
		missing_artifacts: []
		missing_symbols: []
		missing_evidence: []
		failed_validations: []
	}
})

#ContextPacket: close({
	id:    string & =~"^df:context-packet/[a-z0-9._-]+$"
	query: string & !=""

	contracts: [#ProjectedEntity & {kind: "contract"}, ...#ProjectedEntity & {kind: "contract"}]
	nodes: [...#ProjectedEntity & {kind: "node"}]
	implementations: [...#ProjectedEntity & {kind: "implementation"}]
	artifacts: [...#ProjectedEntity & {kind: "artifact"}]
	symbols: [...#ProjectedEntity & {kind: "symbol"}]
	evidence: [...#ProjectedEntity & {kind: "evidence"}]

	edges: [...#Edge]
	provider_routes: [...#ProviderRoute]
	validations: [...graph.#ValidationID]
	exclusions: [...#Exclusion]
	completeness: #Completeness
})

#ReverseDependencyPacket: close({
	id:        string & =~"^df:reverse-packet/[a-z0-9._-]+$"
	entity_id: graph.#ArtifactID | graph.#SymbolID
	query:     string & !=""

	dependent_contracts: [#ProjectedEntity & {kind: "contract"}, ...#ProjectedEntity & {kind: "contract"}]
	implemented_nodes: [...#ProjectedEntity & {kind: "node"}]
	implementations: [...#ProjectedEntity & {kind: "implementation"}]
	validation_profiles: [...graph.#ValidationID]
	edges: [#Edge, ...#Edge]
	completeness: #Completeness
})
