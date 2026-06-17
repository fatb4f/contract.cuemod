package workspacelifecycle

import "github.com/fatb4f/contract.cuemod/contracts/context/packet"

reason: [string]: resolver.#InclusionReason
reason: {
	for id, edge in graphEdges {
		(id): {
			edge_id:   edge.id
			predicate: edge.predicate
			source:    edge.source
			target:    edge.target
		}
	}
}

forward: resolver.#ContextPacket & {
	id:    "df:context-packet/workspace-lifecycle"
	query: "workspace lifecycle capability"

	contracts: [{
		entities["df:contract/workspace-lifecycle"]
		included_because: [{
			edge_id:   "df:edge/workspace-lifecycle-requires-sessionizer"
			predicate: "requires"
			source:    "df:contract/workspace-lifecycle"
			target:    "df:node/sessionizer-entrypoint"
		}]
	}]
	nodes: [
		entities["df:node/sessionizer-entrypoint"] & {
			included_because: [reason["df:edge/workspace-lifecycle-requires-sessionizer"]]
		},
		entities["df:node/wezterm-workspace-controller"] & {
			included_because: [reason["df:edge/workspace-lifecycle-requires-controller"]]
		},
		entities["df:node/neovim-workspace-client"] & {
			included_because: [reason["df:edge/workspace-lifecycle-requires-nvim-client"]]
		},
	]
	implementations: [
		entities["df:implementation/sessionizer-lua"] & {
			included_because: [reason["df:edge/sessionizer-implemented-by-lua"]]
		},
		entities["df:implementation/controller-launch"] & {
			included_because: [reason["df:edge/controller-implemented-by-launch"]]
		},
		entities["df:implementation/nvim-client-command"] & {
			included_because: [reason["df:edge/nvim-client-implemented-by-command"]]
		},
	]
	artifacts: [
		entities["df:artifact/wezterm-sessionizer-lua"] & {
			included_because: [reason["df:edge/sessionizer-stored-in-wezterm"]]
		},
		entities["df:artifact/wezterm-controller-lua"] & {
			included_because: [reason["df:edge/controller-stored-in-wezterm"]]
		},
		entities["df:artifact/nvim-workspace-client-lua"] & {
			included_because: [reason["df:edge/nvim-client-stored-in-nvim"]]
		},
	]
	symbols: [
		entities["df:symbol/sessionizer-select-project"] & {
			included_because: [reason["df:edge/sessionizer-defines-select-project"]]
		},
		entities["df:symbol/controller-launch"] & {
			included_because: [reason["df:edge/controller-defines-launch"]]
		},
		entities["df:symbol/nvim-client-open-workspace"] & {
			included_because: [reason["df:edge/nvim-client-defines-open-workspace"]]
		},
	]
	evidence: [
		entities["df:evidence/sessionizer-select-project"] & {
			included_because: [reason["df:edge/sessionizer-symbol-evidenced"]]
		},
		entities["df:evidence/controller-launch"] & {
			included_because: [reason["df:edge/controller-symbol-evidenced"]]
		},
		entities["df:evidence/nvim-client-open-workspace"] & {
			included_because: [reason["df:edge/nvim-client-symbol-evidenced"]]
		},
	]
	edges: [for _, edge in graphEdges {edge}]
	provider_routes: [
		{
			entity_id:   "df:contract/workspace-lifecycle"
			provider_id: "df:provider/cue-lsp-mcp"
			purpose:     "graph-definition"
		},
		{
			entity_id:   "df:symbol/sessionizer-select-project"
			provider_id: "df:provider/lua-lsp-mcp"
			purpose:     "symbol-evidence"
		},
		{
			entity_id:   "df:artifact/wezterm-sessionizer-lua"
			provider_id: "df:provider/cue-rg-mcp"
			purpose:     "text-verification"
		},
	]
	validations: ["df:validation/workspace-lifecycle"]
	exclusions: [
		{
			entity_id: "df:artifact/xplr-workspace-lua"
			reason:    "no-explicit-edge"
		},
		{
			entity_id: "df:artifact/nvim-unrelated-config"
			reason:    "outside-projection"
		},
	]
	completeness: {
		complete: true
	}
}

reverseByArtifact: resolver.#ReverseDependencyPacket & {
	id:        "df:reverse-packet/wezterm-sessionizer-lua"
	entity_id: "df:artifact/wezterm-sessionizer-lua"
	query:     "what depends on the WezTerm sessionizer artifact?"
	dependent_contracts: [{
		entities["df:contract/workspace-lifecycle"]
		included_because: [reason["df:edge/workspace-lifecycle-requires-sessionizer"]]
	}]
	implemented_nodes: [{
		entities["df:node/sessionizer-entrypoint"]
		included_because: [reason["df:edge/sessionizer-implemented-by-lua"]]
	}]
	implementations: [{
		entities["df:implementation/sessionizer-lua"]
		included_because: [reason["df:edge/sessionizer-stored-in-wezterm"]]
	}]
	validation_profiles: ["df:validation/workspace-lifecycle"]
	edges: [
		graphEdges["df:edge/workspace-lifecycle-requires-sessionizer"],
		graphEdges["df:edge/sessionizer-implemented-by-lua"],
		graphEdges["df:edge/sessionizer-stored-in-wezterm"],
	]
	completeness: {
		complete: true
	}
}

reverseBySymbol: resolver.#ReverseDependencyPacket & {
	id:                  "df:reverse-packet/sessionizer-select-project"
	entity_id:           "df:symbol/sessionizer-select-project"
	query:               "what depends on sessionizer.select_project?"
	dependent_contracts: reverseByArtifact.dependent_contracts
	implemented_nodes:   reverseByArtifact.implemented_nodes
	implementations: [{
		entities["df:implementation/sessionizer-lua"]
		included_because: [reason["df:edge/sessionizer-defines-select-project"]]
	}]
	validation_profiles: reverseByArtifact.validation_profiles
	edges: [
		graphEdges["df:edge/workspace-lifecycle-requires-sessionizer"],
		graphEdges["df:edge/sessionizer-implemented-by-lua"],
		graphEdges["df:edge/sessionizer-defines-select-project"],
	]
	completeness: {
		complete: true
	}
}

incompleteCompleteness: resolver.#Completeness & {
	complete: false
	missing_nodes: []
	missing_edges: []
	missing_implementations: []
	missing_artifacts: []
	missing_symbols: []
	missing_evidence: [
		"df:evidence/sessionizer-select-project",
		"df:evidence/controller-launch",
		"df:evidence/nvim-client-open-workspace",
	]
	failed_validations: ["df:validation/workspace-lifecycle"]
}
