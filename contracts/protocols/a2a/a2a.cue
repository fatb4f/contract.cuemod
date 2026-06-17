package a2a

#EnvelopeKind: "NEW_TASK" | "MESSAGE" | "FINAL_ANSWER"

#PayloadKind: "task" | "message" | "final_answer" | "route_result" | "evidence"

#Envelope: close({
	schema:    "codex.multi-agent.route-envelope.v2"
	kind:      #EnvelopeKind
	routeID:   string & !=""
	sender:    string & =~"^/[A-Za-z0-9._/-]+$"
	recipient: string & =~"^/[A-Za-z0-9._/-]+$"
	payload: close({
		id:   string & !=""
		kind: #PayloadKind
	})
})

domain: {
	id:          "protocols/a2a"
	kind:        "protocol"
	authority:   true
	extractable: true
	imports: []
}
