package agentskillprojection

import agentskill "github.com/fatb4f/contract.cuemod/contracts/agent-skill:agentskill"

projection: agentskill.#SkillProjection & {
	metadata: {
		name:        "resolve-agent-context"
		description: "Resolve authoritative CUE task context before inspecting or editing projected capabilities."
		provenance: {
			projection_id: "df:projection/resolve-agent-context-skill"
			contract_ids: ["df:contract/agent-skill-runtime"]
			generated: true
		}
	}
	hooks: {
		hooks: {
			UserPromptSubmit: [{
				hooks: [{
					type:          "command"
					command:       ".codex/skills/resolve-agent-context/scripts/dotfiles-agent-context-hook"
					timeout:       10
					statusMessage: "Routing dotfiles capability context"
				}]
			}]
		}
	}
	scripts: {
		"dotfiles-agent-context-hook": {
			path:       ".codex/skills/resolve-agent-context/scripts/dotfiles-agent-context-hook"
			content:    "#!/bin/sh\nset -eu\n"
			executable: true
			provenance: metadata.provenance
		}
		"resolve-agent-context": {
			path:       ".codex/skills/resolve-agent-context/scripts/resolve-agent-context"
			content:    "#!/bin/sh\nset -eu\n"
			executable: true
			provenance: metadata.provenance
		}
	}
}
