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

#PromptSelection: {
	projection: #AgentContextProjection
	selectedFragments: [...string]

	let declaredFragmentIDs = [
		for fragment in projection.fragments {
			fragment.id
		},
	]

	for selectedFragment in selectedFragments {
		if !list.Contains(declaredFragmentIDs, selectedFragment) {
			_selectionError: _|_
		}
	}
}

#PromptRoute: close({
	#PromptSelection
	id: =~"^[a-z0-9][a-z0-9._/-]*$"
})

#PromptDerivation: close({
	#PromptSelection
	id:      =~"^[a-z0-9][a-z0-9._/-]*$"
	routeID: =~"^[a-z0-9][a-z0-9._/-]*$"
})
