package invalidundeclared

import (
	agentcontext "github.com/fatb4f/contract.cuemod/contracts/agent-context:agentcontext"
	contextprojection "github.com/fatb4f/contract.cuemod/projections/agent-context:agentcontextprojection"
)

route: agentcontext.#PromptRoute & {
	id:         "route.invalid"
	projection: contextprojection.agentContextProjection
	selectedFragments: ["fragment.not-declared"]
}
