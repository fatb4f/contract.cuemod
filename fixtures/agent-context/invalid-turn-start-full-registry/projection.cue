package invalidturnstartfullregistry

import agentcontext "github.com/fatb4f/contract.cuemod/contracts/agent-context:agentcontext"

fragment: agentcontext.#TurnStartContextFragment & {
	id:                             "generated.turn-start.invalid"
	source:                         "generated"
	surface:                        "turn_start"
	expectedChannel:                "message"
	expectedItemKind:               "message"
	expectedNativeContextInjection: true
	content: {
		title:   "Invalid agent context"
		summary: "Attempts to emit the full registry."
		fragmentIDs: ["registry.agent-capability-routes"]
	}
	constraints: {
		compact:      false
		fullRegistry: true
		generated:    true
	}
}
