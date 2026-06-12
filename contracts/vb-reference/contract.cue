package vbreference

import repo "github.com/fatb4f/contract.cuemod/contracts/repo:repo"

referenceComponent: repo.#Component & {
	id:        "vb-reference.component"
	component: "vb-reference"
	temporary: false
	owns: [
		"contracts/vb-reference/contract.cue",
		"contracts/vb-reference/reference_branch.cue",
	]
	dependsOn: ["vb-contract"]
	allowedGlue: [{
		id:    "repo-registry-contribution"
		paths: ["contracts/registry.cue"]
		reason: "Register the downstream component until registry contributions are discovered automatically."
		removalGate: {
			state:    "pending"
			criteria: ["Registry contributions are discovered without central wiring."]
		}
	}]
	mergeGate: {
		state: "passed"
		criteria: [
			"The concrete component and virtual branch export through shared schemas.",
			"The repository registry contains the vb-reference fragments.",
			"Registry paths, allowed glue, and generated projections validate.",
		]
		evidence: [
			"cue export ./contracts/vb-reference -e referenceComponent",
			"cue export ./contracts/vb-reference -e referenceVirtualBranch",
			"./test/vb-reference-workflow.sh",
		]
	}
	removalOrPromotionGate: {
		state:    "passed"
		criteria: ["The reference consumer uses stable non-seed schemas."]
		evidence: ["cue vet ./contracts/vb-reference"]
	}
}

registryContribution: repo.#RegistryContribution & {
	id:            "vb-reference"
	authorityRoot: "contracts/vb-reference"
	contractPath:  "contracts/vb-reference/contract.cue"
	fragments: [
		{
			id:             "vb-reference.authority"
			sourceContract: "vb-reference"
			sourcePath:     "contracts/vb-reference/contract.cue"
			role:           "authority"
			surface:        "turn_start"
			summary:        "Reference downstream component consuming stable vb-contract schemas."
		},
		{
			id:             "vb-reference.virtual-branch"
			sourceContract: "vb-reference"
			sourcePath:     "contracts/vb-reference/reference_branch.cue"
			role:           "evidence"
			surface:        "turn_start"
			summary:        "Concrete reference virtual branch with ownership, dependencies, glue, and lifecycle gates."
		},
	]
}
