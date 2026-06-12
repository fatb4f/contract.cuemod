package valid

import (
	agentcontext "github.com/fatb4f/contract.cuemod/contracts/agent-context:agentcontext"
	contextprojection "github.com/fatb4f/contract.cuemod/projections/agent-context:agentcontextprojection"
)

route: agentcontext.#PromptRoute & {
	id:         "route.valid"
	projection: contextprojection.agentContextProjection
	selectedFragments: [
		"registry.agent-capability-routes",
		"hook.user-prompt-routing-hint",
	]
}

derivation: agentcontext.#PromptDerivation & {
	id:                "derivation.valid"
	routeID:           route.id
	projection:        contextprojection.agentContextProjection
	selectedFragments: route.selectedFragments
}
