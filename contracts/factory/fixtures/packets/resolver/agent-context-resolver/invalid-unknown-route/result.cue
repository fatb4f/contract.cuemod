package invalidunknownroute

import fixtures "github.com/fatb4f/contract.cuemod/fixtures/resolver/agent-context-resolver:agentcontextresolver"

invalid: fixtures.#FixturePlan & {
	routes: [{
		fixtures.#FixtureRoute
		id: "route.unknown"
	}]
}
