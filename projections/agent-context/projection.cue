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
