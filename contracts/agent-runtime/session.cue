package agentruntime

#Session: close({
	id:        #RuntimeID
	startedAt: string & !=""
	state:     "active" | "closed"
})
