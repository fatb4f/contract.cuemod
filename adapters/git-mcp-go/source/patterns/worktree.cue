package gitmcpgo

worktreePattern: {
	id: "git-mcp-go.worktree"

	authority: {
		loadableFiles: [
			"/home/_404/src/git-mcp-go/AGENTS.cue",
			"/home/_404/src/git-mcp-go/patterns/worktree.cue",
			"/home/_404/src/git-mcp-go/**/*.go",
			"/home/_404/src/git-mcp-go/go.mod",
			"/home/_404/src/git-mcp-go/go.sum",
		]
		deniedFiles: [
			"/home/_404/src/frame/**",
			"/home/_404/src/.codex/**",
			"/home/_404/src/.agents/**",
			"/home/_404/src/* via unbounded scan",
		]
	}

	workflow: {
		stage: "modify"
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
	}
}
