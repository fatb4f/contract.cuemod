package invaliddevelopermessages

import (
	runtime "github.com/fatb4f/contract.cuemod/contracts/agent-runtime:agentruntime"
	fixtures "github.com/fatb4f/contract.cuemod/fixtures/agent-runtime:agentruntime"
)

invalid: runtime.#RuntimeInvocation & {
	schema:            "agent.runtime-invocation.v1"
	invocationID:      "fixture-runtime-invocation"
	workerID:          "codex-route-inspector"
	budgetID:          "inspect-standard"
	routeRef:          fixtures.#FixtureRouteRef
	runtimeProjection: fixtures.#FixtureRuntimeProjection
	inputPolicy: {
		arbitraryPrompt:         false
		rawTranscriptForwarding: false
		rawRegistryDump:         false
		unselectedFragments:     false
		unboundedToolLogs:       false
	}
	lifecycle: {
		state: "pending"
		history: [{state: "pending", at: "2026-06-13T20:00:00Z"}]
	}
	developerMessages: ["unbounded instruction"]
}
