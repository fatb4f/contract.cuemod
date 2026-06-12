package agentcontext

import "list"

#ContextFragment: close({
	id: =~"^[a-z0-9][a-z0-9._/-]*$"

	source: "registry" | "skill" | "hook" | "generated"

	surface: "turn_start" | "user_prompt_submit" | "subagent_start"

	expectedChannel: "message" | "tool_output"

	expectedItemKind: "message" | "function_call_output" | "custom_tool_call_output"

	expectedNativeContextInjection: bool

	if expectedNativeContextInjection {
		expectedChannel:  "message"
		expectedItemKind: "message"
	}

	if expectedChannel != "message" {
		expectedNativeContextInjection: false
	}
})

#AgentContextProjection: close({
	schema: "agent.context-fragment-projection.v1"
	fragments: [#ContextFragment, ...#ContextFragment]
})

#TurnStartContextFragment: close({
	id: =~"^[a-z0-9][a-z0-9._/-]*$"

	source: "registry" | "generated"

	surface: "turn_start"

	expectedChannel:                "message"
	expectedItemKind:               "message"
	expectedNativeContextInjection: true

	content: close({
		title:   string
		summary: string
		fragmentIDs: [string, ...string]
	})

	constraints: close({
		compact:      true
		fullRegistry: false
		generated:    true
	})
})

#TurnStartContextGeneration: {
	schema:      "agent.turn-start-context-fragments.v1"
	#projection: #AgentContextProjection
	fragments: [#TurnStartContextFragment, ...#TurnStartContextFragment]

	let declaredFragmentIDs = [
		for fragment in #projection.fragments {
			fragment.id
		},
	]

	for generatedFragment in fragments {
		for fragmentID in generatedFragment.content.fragmentIDs {
			if !list.Contains(declaredFragmentIDs, fragmentID) {
				_undeclaredFragmentError: _|_
			}
		}
	}
}

#Stage3Proof: close({
	id:     =~"^[a-z0-9][a-z0-9._/-]*$"
	status: "pass"
})

#Stage3ExpectedReport: close({
	schema:           "agent.context-delivery-report.v1"
	projectionSchema: "agent.context-fragment-projection.v1"
	fragmentSchema:   "agent.turn-start-context-fragments.v1"
	proofs: [#Stage3Proof, ...#Stage3Proof]
})

#PromptClassifierHints: close({
	domain?:        =~"^[a-z0-9][a-z0-9._/-]*$"
	workflow?:      =~"^[a-z0-9][a-z0-9._/-]*$"
	authorityRoot?: string
	risk?:          "read-only" | "mutation" | "ambiguous" | "none"
})

#PromptClassifierEvidence: close({
	matchedRules: [...string]
	rejectedRules?: [...string]
})

#PromptClassificationShape: close({
	schema: "agent.prompt-classification.v1"
	prompt: string
	status: "selected" | "unknown" | "ambiguous" | "noop"

	selectedFragments: [...string]
	hints?:   #PromptClassifierHints
	evidence: #PromptClassifierEvidence
})

#PromptClassification: {
	#PromptClassificationShape
	#turnStart:        #TurnStartContextGeneration
	status:            #PromptClassificationShape.status
	selectedFragments: #PromptClassificationShape.selectedFragments
	evidence:          #PromptClassificationShape.evidence

	let declaredFragmentIDs = [
		for generatedFragment in #turnStart.fragments
		for fragmentID in generatedFragment.content.fragmentIDs {
			fragmentID
		},
	]

	for selectedFragment in selectedFragments {
		if !list.Contains(declaredFragmentIDs, selectedFragment) {
			_unknownTurnStartFragment: _|_
		}
	}

	if status == "selected" {
		if len(selectedFragments) == 0 {
			_selectedWithoutFragments: _|_
		}
		if len(evidence.matchedRules) != 1 {
			_selectedWithoutSingleRule: _|_
		}
	}

	if status != "selected" {
		if len(selectedFragments) != 0 {
			_unselectedWithFragments: _|_
		}
	}

	if status == "ambiguous" {
		if len(evidence.matchedRules) < 2 {
			_ambiguousWithoutMultipleRules: _|_
		}
	}
}

#PromptClassifierRule: close({
	id: =~"^[a-z0-9][a-z0-9._/-]*$"
	terms: [string, ...string]
	selectedFragments: [string, ...string]
	hints: #PromptClassifierHints
})

#PromptClassifierRegistryShape: close({
	schema: "agent.prompt-classifier-registry.v1"
	rules: [#PromptClassifierRule, ...#PromptClassifierRule]
})

#PromptClassifierRegistry: {
	#PromptClassifierRegistryShape
	#turnStart: #TurnStartContextGeneration
	rules:      #PromptClassifierRegistryShape.rules

	let declaredFragmentIDs = [
		for generatedFragment in #turnStart.fragments
		for fragmentID in generatedFragment.content.fragmentIDs {
			fragmentID
		},
	]

	for rule in rules {
		for selectedFragment in rule.selectedFragments {
			if !list.Contains(declaredFragmentIDs, selectedFragment) {
				_unknownRuleFragment: _|_
			}
		}
	}
}
