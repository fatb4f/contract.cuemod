package agentcontextresolver

import "list"

#SequencedRouteSet: {
	routes: [...#RouteInvocation] & [_, ...]

	_routeIDs: [for route in routes {route.id}]

	for route in routes {
		for dependencyID in route.dependsOn {
			if !list.Contains(_routeIDs, dependencyID) {
				_invalidDependency: _|_
			}
		}
	}
}
