package valid

import repo "github.com/fatb4f/contract.cuemod/contracts/repo:repo"

componentFixture: repo.#Component & {
	id:        "vb-contract-fixture.component"
	component: "vb-contract-fixture"
	owns: ["fixtures/vb-contract/valid"]
	dependsOn: ["vb-contract"]
	allowedGlue: [{
		id: "contract-seed-bootstrap"
		paths: ["contracts/repo/contract_seed.cue"]
		reason: "Exercise an explicitly temporary bootstrap allowance."
		removalGate: {
			state: "pending"
			criteria: ["The fixture no longer depends on the bootstrap seed."]
		}
	}]
	mergeGate: {
		state: "passed"
		criteria: ["Virtual-branch contract validates."]
		evidence: ["cue vet ./fixtures/vb-contract/valid"]
	}
	removalOrPromotionGate: {
		state: "pending"
		criteria: ["Migration evidence supports promotion or removal."]
	}
}

virtualBranch: repo.#VirtualBranch & {
	id:                     "vb-contract-fixture.branch"
	branchName:             "vb-contract-fixture"
	component:              componentFixture.component
	owns:                   componentFixture.owns
	dependsOn:              componentFixture.dependsOn
	allowedGlue:            componentFixture.allowedGlue
	mergeGate:              componentFixture.mergeGate
	removalOrPromotionGate: componentFixture.removalOrPromotionGate
}
