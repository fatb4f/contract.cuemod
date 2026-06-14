package invalidrawtranscript

import fixtures "github.com/fatb4f/contract.cuemod/fixtures/agent-runtime:agentruntime"

invalid: fixtures.#FixtureInvocation & {
	routeRef: context: rawTranscript: "parent conversation"
}
