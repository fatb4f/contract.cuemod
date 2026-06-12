package repo

#ContractSeed: close({
	id:        string & !=""
	kind:      "contract-seed"
	temporary: true

	schemaSeed: {
		id:       string & !=""
		source:   string & !=""
		renderer: "none"
	}

	templateSeed: {
		id:       string & !=""
		source:   string & !=""
		renderer: "none"
	}

	instanceSeed: {
		id:       string & !=""
		source:   string & !=""
		renderer: "none"
	}

	projectionSeed: {
		id:            string & !=""
		source:        string & !=""
		renderer:      "none"
		targetFragment: string & !=""
	}

	registryFragmentSeed: {
		id:             string & !=""
		authorityRoot:   string & !=""
		contractPath:    string & !=""
		sourcePath:      string & !=""
		fragmentID:      string & !=""
	}

	rebaseTarget: {
		component:    string & !=""
		sourceBranch: string & !=""
		targetBranch: string & !=""
		state:        "temporary"
	}
})

contractSeed: #ContractSeed & {
	id:   "repo.contract-seed"
	kind: "contract-seed"

	schemaSeed: {
		id:       "repo.contract-seed.schema"
		source:   "contracts/repo/contract_seed.cue"
		renderer: "none"
	}

	templateSeed: {
		id:       "repo.contract-seed.template"
		source:   "contracts/repo/contract_seed.cue"
		renderer: "none"
	}

	instanceSeed: {
		id:       "repo.contract-seed.instance"
		source:   "contracts/repo/contract_seed.cue"
		renderer: "none"
	}

	projectionSeed: {
		id:            "repo.contract-seed.projection"
		source:        "contracts/repo/contract_seed.cue"
		renderer:      "none"
		targetFragment: "repo.contract-seed"
	}

	registryFragmentSeed: {
		id:            "repo.contract-seed.registry-fragment"
		authorityRoot: "contracts/repo"
		contractPath:  "contracts/repo/lifecycle.cue"
		sourcePath:    "contracts/repo/contract_seed.cue"
		fragmentID:    "repo.contract-seed"
	}

	rebaseTarget: {
		component:    "vb-contract"
		sourceBranch: "main"
		targetBranch: "vb-contract"
		state:        "temporary"
	}
}
