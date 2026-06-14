package invalidrouteauthority

import "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver:agentcontextresolver"

invalid: agentcontextresolver.#RouteResult & {
	routeID:   "resolver.inspect.current"
	status:    "pass"
	summary:   "Route attempted to become final authority."
	authority: "final"
}
