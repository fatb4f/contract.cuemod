package valid

import "github.com/fatb4f/contract.cuemod/contracts/vcs"

rollbackFixtures: [...vcs.#RollbackFixture] & [
	{
		name: "clean-repo-preflight-abort"
		repoState: {
			clean:         true
			indexDirty:    false
			worktreeDirty: false
			untracked:     false
			conflict:      false
		}
		failureClass:  "preflight_failed"
		rollbackClass: "none"
		snapshotCoverage: []
		expectedState:  "aborted"
		reflogOnly:     false
		manualRequired: false
	},
	{
		name: "ref-mutation-failure"
		repoState: {
			clean:         true
			indexDirty:    false
			worktreeDirty: false
			untracked:     false
			conflict:      false
		}
		failureClass:  "mutation_failed"
		rollbackClass: "ref_only"
		snapshotCoverage: ["head", "refs"]
		expectedState:  "rolled_back"
		reflogOnly:     false
		manualRequired: false
	},
	{
		name: "dirty-index"
		repoState: {
			clean:         false
			indexDirty:    true
			worktreeDirty: false
			untracked:     false
			conflict:      false
		}
		failureClass:  "mutation_failed"
		rollbackClass: "index_only"
		snapshotCoverage: ["index"]
		expectedState:  "rolled_back"
		reflogOnly:     false
		manualRequired: false
	},
	{
		name: "dirty-worktree"
		repoState: {
			clean:         false
			indexDirty:    false
			worktreeDirty: true
			untracked:     false
			conflict:      false
		}
		failureClass:  "mutation_failed"
		rollbackClass: "worktree_only"
		snapshotCoverage: ["worktree"]
		expectedState:  "rolled_back"
		reflogOnly:     false
		manualRequired: false
	},
	{
		name: "ref-and-index-finalize-failure"
		repoState: {
			clean:         false
			indexDirty:    true
			worktreeDirty: false
			untracked:     false
			conflict:      false
		}
		failureClass:  "mutation_failed"
		rollbackClass: "ref_index"
		snapshotCoverage: ["head", "refs", "index"]
		expectedState:  "rolled_back"
		reflogOnly:     false
		manualRequired: false
	},
	{
		name: "untracked-stack-rewrite"
		repoState: {
			clean:         false
			indexDirty:    true
			worktreeDirty: true
			untracked:     true
			conflict:      false
		}
		failureClass:  "mutation_failed"
		rollbackClass: "ref_index_worktree"
		snapshotCoverage: ["head", "refs", "index", "worktree", "untracked"]
		expectedState:  "rolled_back"
		reflogOnly:     false
		manualRequired: false
	},
	{
		name: "patch-apply-conflict"
		repoState: {
			clean:         false
			indexDirty:    true
			worktreeDirty: true
			untracked:     false
			conflict:      true
		}
		failureClass:  "mutation_failed"
		rollbackClass: "conflict_state"
		snapshotCoverage: ["index", "worktree", "conflict_state"]
		expectedState:  "rolled_back"
		reflogOnly:     false
		manualRequired: false
	},
	{
		name: "evidence-write-failure"
		repoState: {
			clean:         true
			indexDirty:    false
			worktreeDirty: false
			untracked:     false
			conflict:      false
		}
		failureClass:  "mutation_failed"
		rollbackClass: "adapter_artifact"
		snapshotCoverage: ["adapter_artifacts"]
		expectedState:  "rolled_back"
		reflogOnly:     false
		manualRequired: false
	},
	{
		name: "postflight-failure"
		repoState: {
			clean:         false
			indexDirty:    true
			worktreeDirty: true
			untracked:     false
			conflict:      false
		}
		failureClass:  "postflight_failed"
		rollbackClass: "ref_index_worktree"
		snapshotCoverage: ["head", "refs", "index", "worktree", "untracked"]
		expectedState:  "rolled_back"
		reflogOnly:     false
		manualRequired: false
	},
	{
		name: "rollback-failure"
		repoState: {
			clean:         false
			indexDirty:    true
			worktreeDirty: true
			untracked:     true
			conflict:      true
		}
		failureClass:  "rollback_failed"
		rollbackClass: "manual_required"
		snapshotCoverage: ["head", "refs", "index", "worktree", "untracked", "conflict_state", "adapter_artifacts"]
		expectedState:  "rollback_failed"
		reflogOnly:     false
		manualRequired: true
	},
]
