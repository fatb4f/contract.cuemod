package invalid

import agentskill "github.com/fatb4f/contract.cuemod/contracts/agent-skill:agentskill"

script: agentskill.#ScriptAsset & {
	path:       "/home/_404/src/contract.cuemod/bin/resolve-agent-context"
	content:    "#!/bin/sh\nset -eu\n"
	executable: true
	provenance: {
		projection_id: "df:projection/resolve-agent-context-skill"
		contract_ids: ["df:contract/agent-skill-runtime"]
		generated: true
	}
}
