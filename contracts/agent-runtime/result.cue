package agentruntime

import resolver "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver:agentcontextresolver"

#RuntimeResult: close({
	invocation: {...}
	_validatedInvocation: #RuntimeInvocation & invocation

	schema:       "agent.runtime-result.v1"
	invocationID: invocation.invocationID
	workerID:     invocation.workerID
	routeRef:     invocation.routeRef
	lifecycle: #ExecutionLifecycle & {
		state: "completed" | "failed" | "blocked"
	}
	budget: #ExecutionBudget & {
		id: invocation.budgetID
	}
	usage: #RuntimeUsage
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
