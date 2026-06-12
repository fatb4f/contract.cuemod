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
			contractPath:  "contracts/agent-context-resolver/contract.cue"
			hooks: {
				turnStart:        true
				userPromptSubmit: true
			}
			fragments: [
				{
					id:             "agent-context-resolver.authority"
					sourceContract: "agent-context-resolver"
					sourcePath:     "contracts/agent-context-resolver/contract.cue"
					role:           "authority"
					surface:        "turn_start"
					summary:        "Authoritative resolver lifecycle and context selection boundary."
				},
				{
					id:             "agent-context-resolver.prompt-routing"
					sourceContract: "agent-context-resolver"
					sourcePath:     "contracts/agent-context-resolver/prompt-routing.cue"
					role:           "workflow"
					surface:        "prompt"
					summary:        "Prompt classifier route hints and declared fragment selection rules."
				},
			]
		},
		{
			id:            "vcs-patch-stack"
			authorityRoot: "contracts/vcs-patch-stack"
			contractPath:  "contracts/vcs-patch-stack/contract.cue"
			fragments: [{
				id:             "vcs-patch-stack.workflow"
				sourceContract: "vcs-patch-stack"
				sourcePath:     "contracts/vcs-patch-stack/contract.cue"
				role:           "workflow"
				surface:        "turn_start"
				summary:        "Patch stack ownership, ordering, and validation workflow."
			}]
		},
		{
			id:            "mcp-toolbox"
			authorityRoot: "contracts/mcp-toolbox"
			contractPath:  "contracts/mcp-toolbox/base-server.cue"
			fragments: [{
				id:             "mcp-toolbox.base-server"
				sourceContract: "mcp-toolbox"
				sourcePath:     "contracts/mcp-toolbox/base-server.cue"
				role:           "constraint"
				surface:        "turn_start"
				summary:        "Base MCP server capability and evidence-plane constraints."
			}]
		},
		{
			id:            "plugin-bundle"
			authorityRoot: "contracts/plugin-bundle"
			contractPath:  "contracts/plugin-bundle/contract.cue"
			fragments: [{
				id:             "plugin-bundle.orientation"
				sourceContract: "plugin-bundle"
				sourcePath:     "contracts/plugin-bundle/contract.cue"
				role:           "orientation"
				surface:        "turn_start"
				summary:        "Plugin bundle discovery and ownership orientation."
			}]
		},
		{
			id:            "code-intel"
			authorityRoot: "contracts/code-intel"
			contractPath:  "contracts/code-intel/contract.cue"
			fragments: [{
				id:             "code-intel.workflow"
				sourceContract: "code-intel"
				sourcePath:     "contracts/code-intel/contract.cue"
				role:           "workflow"
				surface:        "turn_start"
				summary:        "Code intelligence discovery and evidence workflow."
			}]
		},
		{
			id:            "generator-projects"
			authorityRoot: "contracts/generators"
			contractPath:  "contracts/generators/contract.cue"
			fragments: [{
				id:             "generator-projects.constraints"
				sourceContract: "generator-projects"
				sourcePath:     "contracts/generators/contract.cue"
				role:           "constraint"
				surface:        "turn_start"
				summary:        "Generator source, generated output, and validation boundaries."
			}]
		},
	]
}
