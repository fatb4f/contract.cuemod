package agentruntime

#ExecutionBudget: close({
	id:                #RuntimeID
	maxInputTokens:    int & >0
	maxOutputTokens:   int & >0
	maxEvidenceTokens: int & >0
	maxSummaryTokens:  int & >0
})

executionBudgets: [...#ExecutionBudget] & [
	{
		id:                "inspect-standard"
		maxInputTokens:    12000
		maxOutputTokens:   3000
		maxEvidenceTokens: 1600
		maxSummaryTokens:  800
	},
	{
		id:                "validate-standard"
		maxInputTokens:    16000
		maxOutputTokens:   5000
		maxEvidenceTokens: 2400
		maxSummaryTokens:  1000
	},
]

#RuntimeUsage: close({
	inputTokens:    int & >=0
	outputTokens:   int & >=0
	evidenceTokens: int & >=0
	summaryTokens:  int & >=0
})

#BudgetedUsage: close({
	budget: #ExecutionBudget
	usage:  #RuntimeUsage

	usage: {
		inputTokens:    <=budget.maxInputTokens
		outputTokens:   <=budget.maxOutputTokens
		evidenceTokens: <=budget.maxEvidenceTokens
		summaryTokens:  <=budget.maxSummaryTokens
	}
})
