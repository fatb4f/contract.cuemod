package agentruntime

#RuntimeEvidence: close({
	id:      #RuntimeID
	kind:    "contract" | "command" | "tool-result" | "adapter-output"
	ref:     string & !=""
	summary: string & !=""
})
