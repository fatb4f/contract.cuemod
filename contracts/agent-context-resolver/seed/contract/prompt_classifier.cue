package seedresolver

#PromptRoute: {
	id: string
	terms: [...string] & [_, ...]
	selects: [...string] & [_, ...]
	invokes: [...string] & [_, ...]
	hint:     string
	priority: int & >=0
}

promptRoutes: [...#PromptRoute] & [
	{
		id: "resolver"
		terms: ["resolver", "context", "prompt", "hook", "turnstart"]
		selects: ["agent-context-resolver.authority"]
		invokes: ["resolver.inspect.current", "resolver.plan.compile"]
		hint:     "Apply the resolver lifecycle and generated-fragment boundary."
		priority: 100
	},
	{
		id: "patch-stack"
		terms: ["patch", "stack", "rebase"]
		selects: ["vcs.patch-stack"]
		invokes: ["vcs.patch-stack.inspect"]
		hint:     "Apply the declared patch-stack workflow."
		priority: 80
	},
	{
		id: "mcp"
		terms: ["mcp", "tool", "server"]
		selects: ["mcp.evidence-plane"]
		invokes: ["mcp.evidence.inspect"]
		hint:     "Keep MCP results in the evidence plane."
		priority: 80
	},
	{
		id: "skill"
		terms: ["skill", "hook", "codex"]
		selects: ["agent-skill.projection"]
		invokes: ["agent-skill.projection.validate"]
		hint:     "Apply the generated agent skill and hook projection constraints."
		priority: 70
	},
	{
		id: "context-packet"
		terms: ["context packet", "dependency", "projection"]
		selects: ["resolver.context-packet"]
		invokes: ["resolver.context-packet.inspect"]
		hint:     "Apply the context packet projection workflow."
		priority: 70
	},
	{
		id: "repo"
		terms: ["repository", "generated", "fixture"]
		selects: ["repo.lifecycle"]
		invokes: ["repo.lifecycle.validate"]
		hint:     "Preserve repository lifecycle and generated-output boundaries."
		priority: 70
	},
]
