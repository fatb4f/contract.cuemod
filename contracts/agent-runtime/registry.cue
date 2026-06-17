package agentruntime

import (
	"list"

	adaptercontracts "github.com/fatb4f/contract.cuemod/contracts/agent-runtime/adapters:agentruntimeadapters"
)

#RuntimeRouteRegistration: close({
	routeID:   #RuntimeID
	routeKind: #RouteKind
	allowedWorkers: [...#RuntimeID] & [_, ...]
})

#AgentRuntimeRegistry: close({
	schema: "agent.runtime-registry.v1"
	workers: [...#WorkerProfile] & [_, ...]
	budgets: [...#ExecutionBudget] & [_, ...]
	routes: [...#RuntimeRouteRegistration] & [_, ...]
	adapters: close({
		mcpRouteExecutor: adaptercontracts.#MCPRouteExecutorAdapter
		codexSDKBackend:  adaptercontracts.#CodexSDKBackend
	})
})

runtimeRegistry: #AgentRuntimeRegistry & {
	schema:  "agent.runtime-registry.v1"
	workers: workerProfiles
	budgets: executionBudgets
	routes: [
		{routeID: "resolver.inspect.current", routeKind: "inspect", allowedWorkers: ["codex-route-inspector"]},
		{routeID: "resolver.plan.compile", routeKind: "validate", allowedWorkers: ["codex-route-validator"]},
		{routeID: "vcs.patch-stack.inspect", routeKind: "inspect", allowedWorkers: ["codex-route-inspector"]},
		{routeID: "mcp.evidence.inspect", routeKind: "inspect", allowedWorkers: ["codex-route-inspector"]},
		{routeID: "agent-skill.projection.validate", routeKind: "validate", allowedWorkers: ["codex-route-validator"]},
		{routeID: "resolver.context-packet.inspect", routeKind: "inspect", allowedWorkers: ["codex-route-inspector"]},
		{routeID: "repo.lifecycle.validate", routeKind: "validate", allowedWorkers: ["codex-route-validator"]},
	]
	adapters: {
		mcpRouteExecutor: adaptercontracts.mcpRouteExecutor
		codexSDKBackend:  adaptercontracts.codexSDKBackend
	}
}

_workerIDs: [for worker in runtimeRegistry.workers {worker.id}]
_budgetIDs: [for budget in runtimeRegistry.budgets {budget.id}]
_adapterIDs: [
	runtimeRegistry.adapters.mcpRouteExecutor.id,
	runtimeRegistry.adapters.codexSDKBackend.id,
]

runtimeRegistryValidation: {
	for worker in runtimeRegistry.workers {
		if !list.Contains(_budgetIDs, worker.budgetID) {
			_unknownBudget: _|_
		}
		if !list.Contains(_adapterIDs, worker.executorAdapterID) {
			_unknownExecutorAdapter: _|_
		}
		if !list.Contains(_adapterIDs, worker.backendAdapterID) {
			_unknownBackendAdapter: _|_
		}
	}
	for route in runtimeRegistry.routes {
		for workerID in route.allowedWorkers {
			if !list.Contains(_workerIDs, workerID) {
				_unknownWorker: _|_
			}
		}
	}
}

#ResolverRuntimeHandoff: close({
	runtimeProjection: {
		routeRefs: [...#RuntimeRouteReference]
		...
	}
	invocation: {...}
	result: {...}

	_validatedProjection: #RuntimeProjection & runtimeProjection & {
		mode: "eligible"
		execution: allowed: true
	}
	_validatedInvocation: #RuntimeInvocation & invocation & {
		runtimeProjection: runtimeProjection
	}
	_validatedResult: #RuntimeResult & result & {
		invocation: invocation
	}

	_registeredRouteKinds: [
		for route in runtimeRegistry.routes {
			"\(route.routeID)|\(route.routeKind)"
		},
	]
	for ref in runtimeProjection.routeRefs {
		if !list.Contains(_registeredRouteKinds, "\(ref.routeID)|\(ref.routeKind)") {
			_runtimeRouteDrift: _|_
		}
	}
})
