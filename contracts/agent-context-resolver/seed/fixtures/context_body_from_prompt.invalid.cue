package seedresolver

fixtures: {
	context_body_from_prompt: {
		prompt: "Assemble the selected context body."
		selectedFragments: ["agent-context-resolver.authority"]
		contextBodies: [{
			id:   "agent-context-resolver.authority"
			body: "Injected authority body."
		}]
	}
}
