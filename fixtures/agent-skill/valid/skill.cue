package valid

import agentskill "github.com/fatb4f/contract.cuemod/contracts/agent-skill:agentskill"

skill: agentskill.#SkillProjection & {
	metadata: {
		name:        "resolve-agent-context"
		description: "Resolve authoritative CUE task context."
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
					statusMessage: "Routing context"
				}]
			}]
		}
	}
	scripts: {
		"resolve-agent-context": {
			path: ".codex/skills/resolve-agent-context/scripts/resolve-agent-context"
			content: """
				#!/bin/sh
				set -eu
				script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
				contract_root=${CONTRACT_CUEMOD_ROOT:-$(CDPATH= cd -- "$script_dir/../../../.." && pwd -P)}
				"""
			executable: true
			provenance: metadata.provenance
		}
	}
}
