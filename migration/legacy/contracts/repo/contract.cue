package repo

let contractSeedInstance = contractSeed

#ContractTemplateSeed: close({
	id:        string & !=""
	source:    #OwnedPath
	renderer:  "none"
	temporary: true
})

#ProjectionSeed: close({
	id:             string & !=""
	source:         #OwnedPath
	renderer:       "none"
	targetFragment: string & !=""
	temporary:      true
})

#RegistryFragmentContribution: close({
	id:             string & !=""
	sourceContract: #ComponentID
	sourcePath:     #OwnedPath
	role:           "authority" | "orientation" | "workflow" | "constraint" | "evidence"
	surface:        "turn_start" | "prompt" | "subagent"
	summary:        string & !=""
})

#RegistryContribution: close({
	id:            #ComponentID
	authorityRoot: #OwnedPath
	contractPath:  #OwnedPath
	fragments: [
		#RegistryFragmentContribution & {sourceContract: id},
		...#RegistryFragmentContribution & {sourceContract: id},
	]
})

#VBContractSeed: close({
	id:        "vb-contract"
	kind:      "virtual-branch-contract"
	temporary: true

	contractSeed:         #ContractSeed
	componentSeed:        #ComponentSeed
	virtualBranchSeed:    #VirtualBranchSeed
	registryContribution: #RegistryContribution
})

vbContract: #VBContractSeed & {
	temporary:    true
	contractSeed: contractSeedInstance

	componentSeed: {
		id:        "vb-contract.component"
		component: "vb-contract"
		temporary: true
		owns: [
			"contracts/repo/contract.cue",
			"contracts/repo/contract_seed.cue",
			"contracts/repo/component_seed.cue",
			"contracts/repo/virtual_branch.cue",
		]
		dependsOn: ["contract-seed"]
		allowedGlue: [{
			id: "contract-seed-bootstrap"
			paths: ["contracts/repo/contract_seed.cue"]
			reason: "Retain the bootstrap seed until vb-contract is promoted or removed."
			removalGate: {
				state: "pending"
				criteria: ["All migrated components consume vb-contract schemas."]
			}
		}]
		mergeGate: {
			state: "pending"
			criteria: [
				"Virtual-branch seed validates.",
				"Registry contribution resolves to existing authority paths.",
			]
		}
		removalOrPromotionGate: {
			state: "pending"
			criteria: ["Component migration proves the temporary schema stable or replaceable."]
		}
	}

	virtualBranchSeed: {
		id:                     "vb-contract.branch"
		branchName:             "vb-contract"
		component:              "vb-contract"
		temporary:              true
		owns:                   componentSeed.owns
		dependsOn:              componentSeed.dependsOn
		allowedGlue:            componentSeed.allowedGlue
		mergeGate:              componentSeed.mergeGate
		removalOrPromotionGate: componentSeed.removalOrPromotionGate
	}

	registryContribution: {
		id:            "vb-contract"
		authorityRoot: "contracts/repo"
		contractPath:  "contracts/repo/contract.cue"
		fragments: [
			{
				id:             "vb-contract.authority"
				sourceContract: "vb-contract"
				sourcePath:     "contracts/repo/contract.cue"
				role:           "authority"
				surface:        "turn_start"
				summary:        "Temporary virtual-branch contract root and registry contribution."
			},
			{
				id:             "vb-contract.contract-seed"
				sourceContract: "vb-contract"
				sourcePath:     "contracts/repo/contract_seed.cue"
				role:           "constraint"
				surface:        "turn_start"
				summary:        "Temporary contract, template, instance, and projection bootstrap seed."
			},
			{
				id:             "vb-contract.component-seed"
				sourceContract: "vb-contract"
				sourcePath:     "contracts/repo/component_seed.cue"
				role:           "constraint"
				surface:        "turn_start"
				summary:        "Shared reusable component ownership, dependency, glue, and gate schema."
			},
			{
				id:             "vb-contract.virtual-branch"
				sourceContract: "vb-contract"
				sourcePath:     "contracts/repo/virtual_branch.cue"
				role:           "constraint"
				surface:        "turn_start"
				summary:        "Shared reusable virtual-branch schema with separate temporary bootstrap instances."
			},
		]
	}
}
