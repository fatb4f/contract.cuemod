package agentruntime

#Turn: close({
	id:        #RuntimeID
	sessionID: #RuntimeID
	index:     int & >=0
	state:     "open" | "completed" | "blocked"
})
