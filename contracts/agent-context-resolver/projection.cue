package agentcontextresolver

#ProjectedFragment: {
	id:             string
	sourceContract: string
	sourcePath:     string
	role:           "authority" | "orientation" | "workflow" | "constraint" | "evidence"
	surface:        "turn_start" | "prompt" | "subagent"
	summary:        string
	authorityRoot:  string
	contractPath:   string
}

#FragmentInventory: {
	repo: #RepoContractRegistry.repo
	fragments: [...#ProjectedFragment]
}

fragmentInventory: #FragmentInventory & {
	repo: repoRegistry.repo
	fragments: [
		for contract in repoRegistry.contracts
		for fragment in contract.fragments {
			id:             fragment.id
			sourceContract: fragment.sourceContract
			sourcePath:     fragment.sourcePath
			role:           fragment.role
			surface:        fragment.surface
			summary:        fragment.summary
			authorityRoot:  contract.authorityRoot
			contractPath:   contract.contractPath
		},
	]
}
