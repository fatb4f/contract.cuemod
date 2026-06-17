package agentruntime

import "list"

#InvocationInputPolicy: close({
	arbitraryPrompt:         false
	rawTranscriptForwarding: false
	rawRegistryDump:         false
	unselectedFragments:     false
	unboundedToolLogs:       false
})

#RuntimeInvocation: close({
	schema:       "agent.runtime-invocation.v1"
	invocationID: #RuntimeID
	workerID:     #RuntimeID
	budgetID:     #RuntimeID
	routeRef:     #RuntimeRouteReference
	runtimeProjection: #RuntimeProjection & {
		mode: "eligible"
		execution: allowed: true
	}
	inputPolicy: #InvocationInputPolicy
	lifecycle: #ExecutionLifecycle & {state: "pending"}

	arbitraryPrompt?: _|_
	rawTranscript?:   _|_
	rawRegistry?:     _|_
}) & {
	invocationID:      #RuntimeID
	workerID:          #RuntimeID
	budgetID:          #RuntimeID
	routeRef:          #RuntimeRouteReference
	runtimeProjection: #RuntimeProjection

	_projectionRouteIDs: [for ref in runtimeProjection.routeRefs {ref.routeID}]
	_projectedRouteRefs: [
		for ref in runtimeProjection.routeRefs
		if ref.routeID == routeRef.routeID {
			ref
		},
	]
	_registeredRouteIDs: [for route in runtimeRegistry.routes {route.routeID}]
	_registeredRouteKinds: [
		for route in runtimeRegistry.routes {
			"\(route.routeID)|\(route.routeKind)"
		},
	]
	_registeredWorkerIDs: [for worker in runtimeRegistry.workers {worker.id}]
	_registeredBudgetIDs: [for budget in runtimeRegistry.budgets {budget.id}]
	_routeWorkerPairs: [
		for route in runtimeRegistry.routes
		for allowedWorker in route.allowedWorkers {
			"\(route.routeID)|\(allowedWorker)"
		},
	]
	_workerRouteKinds: [
		for worker in runtimeRegistry.workers
		for routeKind in worker.allowedRouteKinds {
			"\(worker.id)|\(routeKind)"
		},
	]
	_workerBudgetPairs: [
		for worker in runtimeRegistry.workers {
			"\(worker.id)|\(worker.budgetID)"
		},
	]

	if !list.Contains(_projectionRouteIDs, routeRef.routeID) {
		_routeNotProjected: _|_
	}
	if !list.Contains(_registeredRouteIDs, routeRef.routeID) {
		_routeNotRegistered: _|_
	}
	if !list.Contains(_registeredRouteKinds, "\(routeRef.routeID)|\(routeRef.routeKind)") {
		_routeKindNotRegistered: _|_
	}
	if !list.Contains(_registeredWorkerIDs, workerID) {
		_workerNotRegistered: _|_
	}
	if !list.Contains(_registeredBudgetIDs, budgetID) {
		_budgetNotRegistered: _|_
	}
	if !list.Contains(_routeWorkerPairs, "\(routeRef.routeID)|\(workerID)") {
		_workerNotAllowedForRoute: _|_
	}
	if !list.Contains(_workerRouteKinds, "\(workerID)|\(routeRef.routeKind)") {
		_routeKindNotAllowed: _|_
	}
	if !list.Contains(_workerBudgetPairs, "\(workerID)|\(budgetID)") {
		_budgetNotDeclaredForWorker: _|_
	}
}
