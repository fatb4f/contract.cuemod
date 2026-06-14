package invalidarbitraryprompt

import fixtures "github.com/fatb4f/contract.cuemod/fixtures/agent-runtime:agentruntime"

invalid: fixtures.#FixtureInvocation & {
	arbitraryPrompt: "Inspect anything relevant."
}
