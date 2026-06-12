package agentcontextresolver

#PromptRoute: {
	id: string
	terms: [...string] & [_, ...]
	selects: [...string] & [_, ...]
	hint:     string
	priority: int & >=0
}

promptRoutes: [...#PromptRoute] & [
	{
		id: "resolver"
		terms: ["resolver", "context", "prompt", "hook", "turnstart"]
		selects: ["agent-context-resolver.authority"]
		hint:     "Apply the resolver lifecycle and generated-fragment boundary."
		priority: 100
	},
	{
		id: "patch-stack"
		terms: ["patch", "stack", "rebase"]
		selects: ["vcs-patch-stack.workflow"]
		hint:     "Apply the declared patch-stack workflow."
		priority: 80
	},
	{
		id: "mcp"
		terms: ["mcp", "tool", "server"]
		selects: ["mcp-toolbox.base-server"]
		hint:     "Keep MCP results in the evidence plane."
		priority: 80
	},
	{
		id: "plugin"
		terms: ["plugin", "bundle"]
		selects: ["plugin-bundle.orientation"]
		hint:     "Use the plugin bundle authority for discovery."
		priority: 70
	},
	{
		id: "code-intel"
		terms: ["code intel", "search", "symbol"]
		selects: ["code-intel.workflow"]
		hint:     "Apply the code-intelligence evidence workflow."
		priority: 70
	},
	{
		id: "generator"
		terms: ["generator", "generated", "generate"]
		selects: ["generator-projects.constraints"]
		hint:     "Preserve source and generated-output boundaries."
		priority: 70
	},
]
