package agentcontextprojection

import (
	agentcontext "github.com/fatb4f/contract.cuemod/contracts/agent-context:agentcontext"
	"strings"
)

agentContextProjection: agentcontext.#AgentContextProjection & {
	schema: "agent.context-fragment-projection.v1"
	fragments: [
		{
			id:                             "registry.agent-capability-routes"
			source:                         "registry"
			surface:                        "turn_start"
			expectedChannel:                "message"
			expectedItemKind:               "message"
			expectedNativeContextInjection: true
		},
		{
			id:                             "skill.resolve-agent-context"
			source:                         "skill"
			surface:                        "turn_start"
			expectedChannel:                "message"
			expectedItemKind:               "message"
			expectedNativeContextInjection: true
		},
		{
			id:                             "hook.user-prompt-routing-hint"
			source:                         "hook"
			surface:                        "user_prompt_submit"
			expectedChannel:                "message"
			expectedItemKind:               "message"
			expectedNativeContextInjection: true
		},
		{
			id:                             "generated.agent-runtime-assets"
			source:                         "generated"
			surface:                        "turn_start"
			expectedChannel:                "message"
			expectedItemKind:               "message"
			expectedNativeContextInjection: true
		},
	]
}

turnStartContextFragments: agentcontext.#TurnStartContextGeneration & {
	#projection: agentContextProjection
	fragments: [{
		id:                             "generated.turn-start.agent-context"
		source:                         "generated"
		surface:                        "turn_start"
		expectedChannel:                "message"
		expectedItemKind:               "message"
		expectedNativeContextInjection: true
		content: {
			title:   "Agent context"
			summary: "Load the declared stable agent context fragments before prompt routing."
			fragmentIDs: [
				for fragment in agentContextProjection.fragments
				if fragment.surface == "turn_start" {
					fragment.id
				},
			]
		}
		constraints: {
			compact:      true
			fullRegistry: false
			generated:    true
		}
	}]
}

stage3ExpectedReport: agentcontext.#Stage3ExpectedReport & {
	projectionSchema: agentContextProjection.schema
	fragmentSchema:   turnStartContextFragments.schema
	proofs: [
		{id: "turn_start_fragment_generated", status: "pass"},
		{id: "turn_start_fragment_message_surface", status: "pass"},
		{id: "turn_start_fragment_native_context", status: "pass"},
		{id: "turn_start_fragment_declared_ids_only", status: "pass"},
		{id: "turn_start_fragment_compact", status: "pass"},
		{id: "turn_start_fragment_deterministic", status: "pass"},
		{id: "user_prompt_submit_no_full_registry", status: "pass"},
		{id: "mcp_registry_not_context", status: "pass"},
		{id: "stage3_report_consistency", status: "pass"},
	]
}

promptClassifierRegistry: agentcontext.#PromptClassifierRegistry & {
	#turnStart: turnStartContextFragments
	rules: [
		{
			id: "resolve-agent-context"
			terms: ["context", "resolver"]
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
		},
		{
			id: "agent-runtime"
			terms: ["runtime", "mcp", "tool"]
			selectedFragments: ["generated.agent-runtime-assets"]
			hints: {
				domain:        "agent-context"
				workflow:      "agent-runtime"
				authorityRoot: "contracts/mcp"
				risk:          "read-only"
			}
		},
	]
}

promptClassifierInput: {
	prompt: string | *""
}

let normalizedPrompt = strings.ToLower(strings.TrimSpace(promptClassifierInput.prompt))

promptClassifierMatches: [
	for rule in promptClassifierRegistry.rules
	let matchedTerms = [
		for term in rule.terms
		if strings.Contains(normalizedPrompt, term) {
			term
		},
	]
	if len(matchedTerms) > 0 {
		id:                rule.id
		selectedFragments: rule.selectedFragments
		hints:             rule.hints
		matchedTerms:      matchedTerms
	},
]

promptClassification: agentcontext.#PromptClassification & {
	#turnStart: turnStartContextFragments
	schema:     "agent.prompt-classification.v1"
	prompt:     promptClassifierInput.prompt

	if normalizedPrompt == "" {
		status: "noop"
		selectedFragments: []
		hints: {
			risk: "none"
		}
		evidence: {
			matchedRules: []
			rejectedRules: ["empty-prompt"]
		}
	}

	if normalizedPrompt != "" && len(promptClassifierMatches) == 0 {
		status: "unknown"
		selectedFragments: []
		evidence: {
			matchedRules: []
			rejectedRules: ["no-rule-match"]
		}
	}

	if len(promptClassifierMatches) == 1 {
		status:            "selected"
		selectedFragments: promptClassifierMatches[0].selectedFragments
		hints:             promptClassifierMatches[0].hints
		evidence: {
			matchedRules: [promptClassifierMatches[0].id]
		}
	}

	if len(promptClassifierMatches) > 1 {
		status: "ambiguous"
		selectedFragments: []
		hints: {
			risk: "ambiguous"
		}
		evidence: {
			matchedRules: [
				for match in promptClassifierMatches {
					match.id
				},
			]
			rejectedRules: ["ambiguous-rule-match"]
		}
	}
}
