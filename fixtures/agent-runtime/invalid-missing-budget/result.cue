package invalidmissingbudget

import fixtures "github.com/fatb4f/contract.cuemod/fixtures/agent-runtime:agentruntime"

invalid: fixtures.#FixtureInvocation & {
	budgetID?: _|_
}
