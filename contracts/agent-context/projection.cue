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
