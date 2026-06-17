package seedresolver

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
			fragments: [{
				id:             "repo.lifecycle"
				sourceContract: "repo"
				sourcePath:     "contracts/repo/lifecycle.cue"
				role:           "constraint"
				surface:        "turn_start"
				summary:        "Repository source, generated, fixture, and lifecycle boundaries."
			}]
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
	]
}
