package invalidruntimeexecution

import fixtures "github.com/fatb4f/contract.cuemod/fixtures/resolver/agent-context-resolver:agentcontextresolver"

invalid: fixtures.#FixturePlan & {
	runtime: execution: allowed: true
}
