package agentruntime

#ContextWindow: close({
	id:          #RuntimeID
	maxTokens:   int & >0
	usedTokens:  int & >=0
	remaining:   int & >=0
	truncatable: bool
})
