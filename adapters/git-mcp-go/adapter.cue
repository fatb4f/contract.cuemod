package gitmcpgo

import "github.com/fatb4f/contract.cuemod/contracts/adapters"

adapter: adapters.#ManagedAdapter & {
	id:        "df:adapter/git-mcp-go"
	kind:      "source-snapshot"
	authority: "privileged-backend"
	exposure:  "internal-only"

	source: {
		repository: "https://github.com/fatb4f/git-mcp-go"
		forkOf:    "https://github.com/geropl/git-mcp-go"
		branch:    "worktree-v0"
		revision:  "5e951b4acae146d70c57e8feb6495046c477782b"
		archive:   "https://github.com/fatb4f/git-mcp-go/archive/5e951b4acae146d70c57e8feb6495046c477782b.tar.gz"
	}

	materialization: {
		path:             "adapters/git-mcp-go/source"
		nestedGit:        false
		updateStrategy:   "replace-source-snapshot"
		preserveUpstream: true
	}

	runtime: {
		language:   "go"
		module:     "github.com/geropl/git-mcp-go"
		executable: "git-mcp-go"
		modes: [
			"go-git",
			"shell",
		]
	}

	capabilities: [
		"repository-inspection",
		"index-mutation",
		"commit-mutation",
		"linked-worktree-management",
		"cue-projection",
		"cue-semantic-gates",
	]
}
