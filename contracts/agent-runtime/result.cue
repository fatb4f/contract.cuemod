package agentruntime

import resolver "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver:agentcontextresolver"

#RuntimeResult: close({
	schema:       "agent.runtime-result.v1"
	invocationID: #RuntimeID
	workerID:     #RuntimeID
	routeRef:     resolver.#RuntimeRouteReference
	lifecycle: #ExecutionLifecycle & {
		state: "completed" | "failed" | "blocked"
	}
	budget: #ExecutionBudget
	usage:  #RuntimeUsage
	result: resolver.#RouteResult & {
		routeID: routeRef.routeID
	}
	returnToRoot: close({
		schemaValidationRequired: true
		mergePolicyRequired:      true
		finalSynthesisAuthority:  "root_codex"
	})

	_budgetedUsage: #BudgetedUsage & {
		budget: budget
		usage:  usage
	}
})
