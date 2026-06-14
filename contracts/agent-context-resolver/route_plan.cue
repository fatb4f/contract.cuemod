package agentcontextresolver

import "list"

#ResolvedRoutePlan: {
	schema: "agent.route-plan.v1"
	turnID: string & !=""
	intent: #PromptIntent
	availableFragmentIDs: [...#DeclaredID]
	availableRouteIDs: [...#DeclaredID]
	selectedFragments: [...#DeclaredID] & [_, ...]
	routes: [...#RouteInvocation] & [_, ...]
	propagation: #PropagationPlan
	gates: [...#Gate] & [_, ...]
	expectedMerge: #MergePolicy
	runtime?:      #RuntimeProjection

	_routeIDs: [for route in routes {route.id}]

	for fragmentID in selectedFragments {
		if !list.Contains(availableFragmentIDs, fragmentID) {
			_invalidSelectedFragment: _|_
		}
	}
	for route in routes {
		if !list.Contains(availableRouteIDs, route.id) {
			_invalidRoute: _|_
		}
		for fragmentID in route.inputFragments {
			if !list.Contains(selectedFragments, fragmentID) {
				_invalidRouteFragment: _|_
			}
		}
		for dependencyID in route.dependsOn {
			if !list.Contains(_routeIDs, dependencyID) {
				_invalidDependency: _|_
			}
		}
	}
}
