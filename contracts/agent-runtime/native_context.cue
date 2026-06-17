package agentruntime

#NativeContext: close({
	sessionID: #RuntimeID
	turnID:    #RuntimeID
	messages: [...#Message]
	toolCalls: [...#ToolCall]
})
