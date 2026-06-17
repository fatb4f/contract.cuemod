package agentcontextresolver

import "list"

// #ResolvedRoutePlan is the generated controller packet produced by resolver
// authority. It describes route planning inputs, gates, propagation, and merge
// policy; it is not an SDK subagent or a route executor.
#ResolvedRoutePlan: {
	schema:      "agent.route-plan.v1"
	plannerKind: "generated_controller_packet"
	authority:   "resolver_projection"
	turnID:      string & !=""
	intent:      #PromptIntent
	availableFragmentIDs: [...#DeclaredID]
	availableRouteIDs: [...#DeclaredID]
	selectedFragments: [...#DeclaredID] & [_, ...]
	routes: [...#RouteInvocation] & [_, ...]
	propagation: #PropagationPlan
	gates: [...#Gate] & [_, ...]
	expectedMerge:       #MergePolicy
	runtime?:            #RuntimeProjection
	mergeReducer?:       #MergeReducer
	modelSynthesisGate?: #ModelSynthesisGate

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
