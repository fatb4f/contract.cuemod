package promptclassifierinvalidfragment

import (
	agentcontext "github.com/fatb4f/contract.cuemod/contracts/agent-context:agentcontext"
	contextprojection "github.com/fatb4f/contract.cuemod/projections/agent-context:agentcontextprojection"
)

classification: agentcontext.#PromptClassification & {
	#turnStart: contextprojection.turnStartContextFragments
	schema:     "agent.prompt-classification.v1"
	prompt:     "resolve agent context"
	status:     "selected"
	selectedFragments: ["fragment.not-generated-at-turn-start"]
	evidence: {
		matchedRules: ["invalid-fragment"]
	}
}
