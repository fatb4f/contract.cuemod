package valid

import (
	agentcontext "github.com/fatb4f/contract.cuemod/contracts/agent-context:agentcontext"
	contextprojection "github.com/fatb4f/contract.cuemod/projections/agent-context:agentcontextprojection"
)

classification: agentcontext.#PromptClassification & {
	#turnStart: contextprojection.turnStartContextFragments
	schema:     "agent.prompt-classification.v1"
	prompt:     "resolve agent context"
	status:     "selected"
	selectedFragments: [
		"registry.agent-capability-routes",
		"skill.resolve-agent-context",
	]
	hints: {
		domain:        "agent-context"
		workflow:      "resolve-agent-context"
		authorityRoot: "contracts/agent-context"
		risk:          "read-only"
	}
	evidence: {
		matchedRules: ["resolve-agent-context"]
	}
}
