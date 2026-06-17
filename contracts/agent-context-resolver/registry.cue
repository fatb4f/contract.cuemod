package agentcontextresolver

#RepoContractRegistry: {
	repo: {
		id:   string
		root: string
	}

	contracts: [...#ContractAuthority] & [_, ...]
}

#ContractAuthority: {
	id:            string
	authorityRoot: string
	contractPath:  string

	fragments: [...#FragmentDeclaration] & [_, ...]

	hooks?: {
		turnStart?:        bool
		userPromptSubmit?: bool
	}
}

#FragmentDeclaration: {
	id:             string
	sourceContract: string
	sourcePath:     string
	role:           "authority" | "orientation" | "workflow" | "constraint" | "evidence"
	surface:        "turn_start" | "prompt" | "subagent"
	summary:        string
}

repoRegistry: #RepoContractRegistry & {
	repo: {
		id:   "fatb4f/contract.cuemod"
		root: "."
	}

	contracts: [
		{
			id:            "agent-context-resolver"
			authorityRoot: "contracts/agent-context-resolver"
			contractPath:  "contracts/agent-context-resolver/resolver.cue"
			hooks: {
				turnStart:        true
				userPromptSubmit: true
			}
			fragments: [
				{
					id:             "agent-context-resolver.authority"
					sourceContract: "agent-context-resolver"
					sourcePath:     "contracts/agent-context-resolver/resolver.cue"
					role:           "authority"
					surface:        "turn_start"
					summary:        "Authoritative resolver lifecycle and context selection boundary."
				},
				{
					id:             "agent-context-resolver.prompt-routing"
					sourceContract: "agent-context-resolver"
					sourcePath:     "contracts/agent-context-resolver/prompt_classifier.cue"
					role:           "workflow"
					surface:        "prompt"
					summary:        "Prompt classifier route hints and declared fragment selection rules."
				},
			]
		},
		{
			id:            "agent-runtime"
			authorityRoot: "contracts/agent-runtime"
			contractPath:  "contracts/agent-runtime/registry.cue"
			fragments: [{
				id:             "agent-runtime.authority"
				sourceContract: "agent-runtime"
				sourcePath:     "contracts/agent-runtime/registry.cue"
				role:           "authority"
				surface:        "turn_start"
				summary:        "Registered worker, route invocation, budget, lifecycle, adapter, and structured-result boundary."
			}]
		},
		{
			id:            "agent-skill"
			authorityRoot: "contracts/agent-skill"
			contractPath:  "contracts/agent-skill/skill.cue"
			fragments: [{
				id:             "agent-skill.projection"
				sourceContract: "agent-skill"
				sourcePath:     "contracts/agent-skill/skill.cue"
				role:           "constraint"
				surface:        "turn_start"
				summary:        "Generated agent skill, hook, and script projection constraints."
			}]
		},
		{
			id:            "mcp"
			authorityRoot: "contracts/protocols/mcp"
			contractPath:  "contracts/protocols/mcp/mcp.cue"
			fragments: [{
				id:             "mcp.evidence-plane"
				sourceContract: "mcp"
				sourcePath:     "contracts/protocols/mcp/mcp.cue"
				role:           "constraint"
				surface:        "turn_start"
				summary:        "MCP provider, result, and evidence-plane constraints."
			}]
		},
		{
			id:            "resolver"
			authorityRoot: "contracts/context/packet"
			contractPath:  "contracts/context/packet/resolver.cue"
			fragments: [{
				id:             "resolver.context-packet"
				sourceContract: "resolver"
				sourcePath:     "contracts/context/packet/resolver.cue"
				role:           "workflow"
				surface:        "turn_start"
				summary:        "Context packet selection and dependency projection workflow."
			}]
		},
		{
			id:            "repo"
			authorityRoot: "contracts/repo"
			contractPath:  "contracts/repo/lifecycle.cue"
			fragments: [
				{
					id:             "repo.lifecycle"
					sourceContract: "repo"
					sourcePath:     "contracts/repo/lifecycle.cue"
					role:           "constraint"
					surface:        "turn_start"
					summary:        "Repository source, generated, fixture, and lifecycle boundaries."
				},
				{
					id:             "repo.contract-seed"
					sourceContract: "repo"
					sourcePath:     "contracts/repo/contract_seed.cue"
					role:           "authority"
					surface:        "turn_start"
					summary:        "Temporary shared contract atom seed for later vb-contract rebasing."
				},
			]
		},
		{
			id:            "vcs"
			authorityRoot: "contracts/vcs"
			contractPath:  "contracts/vcs/patch_stack_skill.cue"
			fragments: [{
				id:             "vcs.patch-stack"
				sourceContract: "vcs"
				sourcePath:     "contracts/vcs/patch_stack_skill.cue"
				role:           "workflow"
				surface:        "turn_start"
				summary:        "Patch stack ownership, ordering, and validation workflow."
			}]
		},
		{
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
		},
	]
}
