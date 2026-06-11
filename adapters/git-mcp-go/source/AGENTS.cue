package gitmcpgo

node: {
	schemaVersion: "agentNode.v1"

	node: {
		id:     "git-mcp-go"
		domain: "go-git-mcp-server"
		root:   "/home/_404/src/git-mcp-go"
	}

	discovery: {
		keywords: [
			{
				term:   "git-mcp-go"
				kind:   "primary"
				weight: 10
				mapsToPatterns: ["git-mcp-go.worktree"]
			},
			{
				term:   "worktree"
				kind:   "artifact"
				weight: 9
				mapsToPatterns: ["git-mcp-go.worktree"]
			},
			{
				term:   "go"
				kind:   "tool"
				weight: 8
				mapsToPatterns: ["git-mcp-go.worktree"]
			},
		]

		negative: [
			"sibling repo scan without workspace graph selection",
			"gopls as authorization authority",
			"Git state without Git MCP or git CLI evidence",
		]
	}

	authority: {
		taskPatterns: [
			{
				id:        "git-mcp-go.worktree"
				path:      "/home/_404/src/git-mcp-go/patterns/worktree.cue"
				stage:     "modify"
				rationale: "Go-source and worktree tasks for git-mcp-go load only the repo node and the worktree pattern after workspace graph selection."
				owns: [
					"/home/_404/src/git-mcp-go/AGENTS.cue",
					"/home/_404/src/git-mcp-go/patterns/worktree.cue",
					"/home/_404/src/git-mcp-go/**/*.go",
					"/home/_404/src/git-mcp-go/go.mod",
					"/home/_404/src/git-mcp-go/go.sum",
				]
				requires: {
					mcp: [
						"gopls.mcp",
					]
					validations: [
						"gopls.mcp go_workspace or go_file_context",
						"git status --short",
						"go test ./...",
					]
				}
			},
		]

		forbiddenLoads: [
			"/home/_404/src/frame/**",
			"/home/_404/src/.codex/**",
			"/home/_404/src/.agents/**",
			"/home/_404/src/* via unbounded scan",
		]
	}

	workflow: {
		requires: {
			mcp: [
				"gopls.mcp",
			]
			validations: [
				"gopls.mcp go_workspace or go_file_context",
				"git status --short",
				"go test ./...",
			]
			fixtures: [
				"accept.git-mcp-go.worktree",
				"deny.frame",
				"deny.codex",
				"deny.agents",
				"deny.unbounded-sibling-scan",
			]
		}

		closeout: [
			"record selected workspace graph case",
			"record loaded files and denied sibling loads",
			"record gopls.mcp evidence",
			"record Git MCP or git CLI worktree evidence",
		]
	}
}
