package invalidarbitraryprompt

import (
	runtime "github.com/fatb4f/contract.cuemod/contracts/agent-runtime:agentruntime"
	fixtures "github.com/fatb4f/contract.cuemod/fixtures/agent-runtime:agentruntime"
)

invalid: runtime.#RuntimeInvocation & fixtures.fixtureInvocationInput & {
	budgetID:        "inspect-standard"
	arbitraryPrompt: "Inspect anything relevant."
}
