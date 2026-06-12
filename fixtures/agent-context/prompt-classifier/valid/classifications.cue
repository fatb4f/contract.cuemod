package promptclassifiervalid

import (
	agentcontext "github.com/fatb4f/contract.cuemod/contracts/agent-context:agentcontext"
	contextprojection "github.com/fatb4f/contract.cuemod/projections/agent-context:agentcontextprojection"
)

knownWorkflow: agentcontext.#PromptClassification & {
	#turnStart: contextprojection.turnStartContextFragments
	schema:     "agent.prompt-classification.v1"
	prompt:     "resolve agent context for this task"
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

unknownPrompt: agentcontext.#PromptClassification & {
	#turnStart: contextprojection.turnStartContextFragments
	schema:     "agent.prompt-classification.v1"
	prompt:     "rewrite the release notes"
	status:     "unknown"
	selectedFragments: []
	evidence: {
		matchedRules: []
		rejectedRules: ["no-rule-match"]
	}
}

ambiguousPrompt: agentcontext.#PromptClassification & {
	#turnStart: contextprojection.turnStartContextFragments
	schema:     "agent.prompt-classification.v1"
	prompt:     "inspect context resolver runtime tools"
	status:     "ambiguous"
	selectedFragments: []
	hints: {
		risk: "ambiguous"
	}
	evidence: {
		matchedRules: ["resolve-agent-context", "agent-runtime"]
		rejectedRules: ["ambiguous-rule-match"]
	}
}

emptyPrompt: agentcontext.#PromptClassification & {
	#turnStart: contextprojection.turnStartContextFragments
	schema:     "agent.prompt-classification.v1"
	prompt:     ""
	status:     "noop"
	selectedFragments: []
	hints: {
		risk: "none"
	}
	evidence: {
		matchedRules: []
		rejectedRules: ["empty-prompt"]
	}
}
