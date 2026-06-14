package invalidrawregistry

import fixtures "github.com/fatb4f/contract.cuemod/fixtures/agent-runtime:agentruntime"

invalid: fixtures.fixtureInvocationInput & {
	budgetID: "inspect-standard"
	routeRef: context: rawRegistry: {contracts: []}
}
