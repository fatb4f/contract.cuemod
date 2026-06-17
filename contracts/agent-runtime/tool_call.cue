package agentruntime

#ToolCall: close({
	id:      #RuntimeID
	turnID:  #RuntimeID
	name:    string & !=""
	input?:  _
	output?: _
	state:   "pending" | "completed" | "failed"
})
