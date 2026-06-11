package invalidunpushed

import "github.com/fatb4f/contract.cuemod/contract/vcs"

turnCompletion: vcs.#MutationTurnCompletion & {
	kind: "mutation-turn"

	requiredSequence: [
		"stack.stage",
		"stack.prepareEvidence",
		"stack.finalizePatch",
		"stack.push",
	]

	stage: {
		completed: true
		indexTree: "sha256:staged-tree"
	}

	commit: {
		completed: true
		revision:  "0123456789abcdef0123456789abcdef01234567"
	}

	push: {
		completed:      false
		remote:         "origin"
		remoteRef:      "refs/heads/feature"
		pushedRevision: "0123456789abcdef0123456789abcdef01234567"
		verified:       false
	}

	evidence: {
		prepared: true
		sealed:   true
	}

	finalState: {
		worktreeClean:     true
		indexClean:        true
		localRefAtCommit:  true
		remoteRefAtCommit: false
	}
}
