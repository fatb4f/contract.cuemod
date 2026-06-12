package invalidturnstartundeclared

import (
	agentcontext "github.com/fatb4f/contract.cuemod/contracts/agent-context:agentcontext"
	contextprojection "github.com/fatb4f/contract.cuemod/projections/agent-context:agentcontextprojection"
)

generation: agentcontext.#TurnStartContextGeneration & {
	#projection: contextprojection.agentContextProjection
	fragments: [{
		id:                             "generated.turn-start.invalid"
		source:                         "generated"
		surface:                        "turn_start"
		expectedChannel:                "message"
		expectedItemKind:               "message"
		expectedNativeContextInjection: true
		content: {
			title:   "Invalid agent context"
			summary: "References a fragment outside the declared projection."
			fragmentIDs: ["fragment.not-declared"]
		}
		constraints: {
			compact:      true
			fullRegistry: false
			generated:    true
		}
	}]
}
