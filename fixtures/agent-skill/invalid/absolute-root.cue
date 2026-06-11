package invalid

import agentskill "github.com/fatb4f/contract.cuemod/contracts/agent-skill:agentskill"

script: agentskill.#ScriptAsset & {
	path: ".codex/skills/resolve-agent-context/scripts/resolve-agent-context"
	content: """
		#!/bin/sh
		set -eu
		contract_root=/home/_404/src/contract.cuemod
		"""
	executable: true
	provenance: {
		projection_id: "df:projection/resolve-agent-context-skill"
		contract_ids: ["df:contract/agent-skill-runtime"]
		generated: true
	}
}
