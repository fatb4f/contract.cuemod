package agentruntime

domain: {
	id:          "agent-runtime"
	kind:        "runtime"
	authority:   true
	extractable: true
	imports: ["context/packet", "adapters"]
}
