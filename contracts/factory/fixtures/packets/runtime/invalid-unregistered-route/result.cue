package invalidunregisteredroute

import fixtures "github.com/fatb4f/contract.cuemod/fixtures/agent-runtime:agentruntime"

invalid: fixtures.#FixtureInvocation & {
	routeRef: routeID: "route.unregistered"
	runtimeProjection: routeRefs: [{
		fixtures.#FixtureRouteRef
		routeID: "route.unregistered"
	}]
}
