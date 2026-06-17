package agentruntime

#MessageRole: "system" | "developer" | "user" | "assistant" | "tool"

#Message: close({
	id:     #RuntimeID
	turnID: #RuntimeID
	role:   #MessageRole
	body:   string
})
