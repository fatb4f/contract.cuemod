package agentcontextprojection

import agentcontext "github.com/fatb4f/contract.cuemod/contracts/agent-context:agentcontext"

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

promptRoute: agentcontext.#PromptRoute & {
	id:         "route.resolve-agent-context"
	projection: agentContextProjection
	selectedFragments: [
		"registry.agent-capability-routes",
		"skill.resolve-agent-context",
		"hook.user-prompt-routing-hint",
	]
}

promptDerivation: agentcontext.#PromptDerivation & {
	id:                "derivation.resolve-agent-context"
	routeID:           promptRoute.id
	projection:        agentContextProjection
	selectedFragments: promptRoute.selectedFragments
}
