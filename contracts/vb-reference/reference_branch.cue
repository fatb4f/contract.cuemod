package vbreference

import repo "github.com/fatb4f/contract.cuemod/contracts/repo:repo"

referenceVirtualBranch: repo.#VirtualBranch & {
	id:                     "vb-reference.branch"
	branchName:             "vb-reference"
	component:              referenceComponent.component
	temporary:              false
	owns:                   referenceComponent.owns
	dependsOn:              referenceComponent.dependsOn
	allowedGlue:            referenceComponent.allowedGlue
	mergeGate:              referenceComponent.mergeGate
	removalOrPromotionGate: referenceComponent.removalOrPromotionGate
}
