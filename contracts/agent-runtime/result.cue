package agentruntime

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
	result: #RuntimeRouteResult & {
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
