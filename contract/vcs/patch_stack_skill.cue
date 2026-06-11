package vcs

#SkillOperationClass:
	"read" |
	"prepare" |
	"local-mutation" |
	"finalize" |
	"publish" |
	"rollback" |
	"privileged"

#ApprovalClass:
	"none" |
	"local-mutation" |
	"finalize" |
	"rollback" |
	"privileged"

#PublicOperationID:
	"stack.status" |
	"stack.startPatch" |
	"stack.activatePatch" |
	"stack.stage" |
	"stack.prepareEvidence" |
	"stack.finalizePatch" |
	"stack.push" |
	"stack.compareRevision" |
	"stack.rollback" |
	"evidence.prepare" |
	"evidence.record" |
	"evidence.seal" |
	"evidence.inspect"

#StackStageRequest: close({
	activePatchID: string & !=""
	paths: [string & !="", ...(string & !="")]
	hunkPatch?: string & !=""
})

#StackStageResponse: close({
	transaction: close({
		transactionID: string & !=""
		command:       "stack.stage"
		state:         "committed"
		ok:            true
		evidence: [#EvidenceRef, ...#EvidenceRef]
	})
	stagedPaths: [string & !="", ...(string & !="")]
})

#SkillOperation: close({
	id:          #PublicOperationID
	class:       #SkillOperationClass
	agentFacing: true

	requires: close({
		activeStack:   bool | *true
		activePatch:   bool | *false
		cleanWorktree: bool | *false
		transaction:   bool | *false
		evidence:      bool | *false
		commit:        bool | *false
		approval:      #ApprovalClass | *"none"
	})

	effects: close({
		reads: [...string & !=""] | *[]
		writes: [...string & !=""] | *[]
		createsCommit:   bool | *false
		changesRef:      bool | *false
		changesIndex:    bool | *false
		changesWorktree: bool | *false
		pushesRemote:    bool | *false
	})

	backendCapabilities: [string & =~"^(vcs|evidence)\\.", ...(string & =~"^(vcs|evidence)\\.")]
	forbiddenBackends: [...string & !=""] | *["git-cli"]
	rationale:          string & !=""
	transactionPolicy?: #CommandTransactionPolicy

	if len(effects.writes) > 0 {
		requires: transaction: true
	}

	if class == "local-mutation" || class == "finalize" || class == "rollback" {
		requires: {
			activePatch: true
			transaction: true
		}
	}

	if id == "stack.stage" || id == "stack.finalizePatch" || id == "stack.rollback" {
		transactionPolicy: #CommandTransactionPolicy
	}

	if class == "finalize" {
		requires: evidence: true
	}

	if class == "publish" {
		requires: {
			activePatch: true
			transaction: true
			evidence:    true
			commit:      true
		}
		effects: pushesRemote: true
	}
})

#ForbiddenAgentCapability: close({
	namespace: "vcs.*" | "cue.*" | "cue_lsp.*"
	reason:    string & !=""
})

#MutationTurnCompletion: close({
	kind: "mutation-turn"

	requiredSequence: [
		"stack.stage",
		"stack.prepareEvidence",
		"stack.finalizePatch",
		"stack.push",
	]

	stage: close({
		completed: true
		indexTree: string & !=""
	})

	commit: close({
		completed: true
		revision:  string & =~"^[0-9a-f]{40}$"
	})

	push: close({
		completed:      true
		remote:         string & !=""
		remoteRef:      string & =~"^refs/"
		pushedRevision: string & =~"^[0-9a-f]{40}$"
		verified:       true
	})

	evidence: close({
		prepared: true
		sealed:   true
	})

	finalState: close({
		worktreeClean:     true
		indexClean:        true
		localRefAtCommit:  true
		remoteRefAtCommit: true
	})

	push: pushedRevision: commit.revision
})

#PatchStackSkillContract: close({
	id:      "skill/vcs-patch-stack"
	version: string & =~"^v[0-9]+\\.[0-9]+\\.[0-9]+$"

	objective: string & !=""

	scope: close({
		owns: [string & !="", ...(string & !="")]
		doesNotOwn: [string & !="", ...(string & !="")]
	})

	agentSurface: close({
		defaultNamespace: "stack"
		allowed: [#SkillOperation, ...#SkillOperation]
		forbidden: [#ForbiddenAgentCapability, ...#ForbiddenAgentCapability]
	})

	privilegedBackends: close({
		vcs: close({
			backend:               "go-git"
			rawAgentAccess:        false
			gitCLIFallbackAllowed: false
			capabilities: [string & =~"^vcs\\.", ...(string & =~"^vcs\\.")]
		})
		cue: close({
			rawAgentAccess: false
		})
		cueLSP: close({
			rawAgentAccess: false
		})
	})

	invariants: close({
		patchIdentityIndependentOfCommitSHA:  true
		stackOrderExplicit:                   true
		mutationsRequireActivePatch:          true
		mutationsRequireTransaction:          true
		evidenceBeforeFinalCommit:            true
		mutationTurnRequiresStage:            true
		mutationTurnRequiresCommit:           true
		mutationTurnRequiresPush:             true
		pushRequiresSealedEvidence:           true
		turnEndRequiresCleanWorktreeAndIndex: true
		turnEndRequiresRemoteVerification:    true
		nativeCompareRevision:                true
		noGitCLIInCoreVCSAdapter:             true
		rawBackendCapabilitiesPrivileged:     true
		publicOperationsUseStablePatchID:     true
		publicOperationsDoNotExposeCommitSHA: true
	})

	transactions: close({
		requiredFor: [
			"stack.startPatch",
			"stack.activatePatch",
			"stack.stage",
			"stack.prepareEvidence",
			"stack.finalizePatch",
			"stack.push",
			"stack.rollback",
			"evidence.prepare",
			"evidence.record",
			"evidence.seal",
		]
		journalBeforeMutation: true
		recordPreState:        true
		recordPostState:       true
	})

	turnCompletion: close({
		requiredForMutationTurns: true
		schema:                   "#MutationTurnCompletion"
		requiredSequence: [
			"stack.stage",
			"stack.prepareEvidence",
			"stack.finalizePatch",
			"stack.push",
		]
		requiresStage:              true
		requiresPreparedEvidence:   true
		requiresSealedEvidence:     true
		requiresCommit:             true
		requiresPush:               true
		requiresRemoteVerification: true
		requiresCleanWorktree:      true
		requiresCleanIndex:         true
		requiresLocalRemoteParity:  true
		failureMode:                "turn-must-remain-open"
	})

	evidence: close({
		requiredForFinalize: true
		subject:             "staged-tree" | "draft-commit"
		prepareBeforeCommit: true
		sealAfterCommit:     true
		recordsImmutable:    true
	})

	rollback: close({
		requiredForMutations:       true
		transactionJournalRequired: true
		reflogAloneSufficient:      false
		restoreIndex:               true
		restoreWorktree:            true
		restoreRefs:                true
		preserveEvidence:           true
	})
})

patchStackSkill: #PatchStackSkillContract & {
	version:   "v1.0.0"
	objective: "Expose safe patch-stack and evidence workflows without granting agents raw VCS or CUE backend access."

	scope: {
		owns: [
			"patch identity and metadata",
			"explicit stack order",
			"patch activation and staging",
			"commit publication and remote verification",
			"revision comparison",
			"transaction journals",
			"patch evidence lifecycle",
			"patch rollback",
		]
		doesNotOwn: [
			"pull request orchestration",
			"raw Git object access",
			"CUE command execution",
			"CUE LSP lifecycle",
		]
	}

	agentSurface: {
		allowed: [
			{
				id:          "stack.status"
				class:       "read"
				agentFacing: true
				requires: {}
				effects: {
					reads: ["stack metadata", "patch metadata", "Git status"]
				}
				backendCapabilities: ["vcs.status", "vcs.readRefs", "vcs.readIndex"]
				transactionPolicy: {
					mode: "exempt"
					requiredSnapshotSurfaces: []
					postflightPredicates: []
					priorTransactionIDAllowed: false
				}
				rationale: "Report stack, active patch, index, and worktree state without mutation."
			},
			{
				id:          "stack.startPatch"
				class:       "prepare"
				agentFacing: true
				requires: {
					transaction: true
					approval:    "local-mutation"
				}
				effects: {
					writes: ["patch metadata", "stack order", "transaction journal"]
				}
				backendCapabilities: ["vcs.readHead", "vcs.writePatchMetadata", "vcs.writeTransaction"]
				rationale: "Create a stable patch identity and append it to explicit stack order before content mutation."
			},
			{
				id:          "stack.activatePatch"
				class:       "local-mutation"
				agentFacing: true
				requires: {
					activePatch: true
					transaction: true
					approval:    "local-mutation"
				}
				effects: {
					reads: ["patch metadata", "transaction journal"]
					writes: ["active patch state", "index", "worktree"]
					changesIndex:    true
					changesWorktree: true
				}
				backendCapabilities: ["vcs.readTree", "vcs.checkoutTree", "vcs.writeIndex", "vcs.writeTransaction"]
				rationale: "Activate a patch by stable patch identity under a recoverable transaction."
			},
			{
				id:          "stack.stage"
				class:       "local-mutation"
				agentFacing: true
				requires: {
					activePatch: true
					transaction: true
					approval:    "local-mutation"
				}
				effects: {
					reads: ["worktree", "patch metadata"]
					writes: ["index", "transaction journal"]
					changesIndex: true
				}
				backendCapabilities: ["vcs.readWorktree", "vcs.writeIndex", "vcs.writeTransaction"]
				transactionPolicy: {
					mode:                "required"
					transactionContract: "#Transaction"
					requiredSnapshotSurfaces: ["head", "refs", "index", "worktree", "untracked", "operation_input"]
					postflightPredicates: ["selected paths staged", "worktree preserved", "transaction evidence updated"]
					priorTransactionIDAllowed: false
				}
				rationale: "Stage paths only into the active patch transaction."
			},
			{
				id:          "stack.prepareEvidence"
				class:       "prepare"
				agentFacing: true
				requires: {
					activePatch: true
					transaction: true
				}
				effects: {
					reads: ["index", "patch metadata"]
					writes: ["draft evidence", "transaction journal"]
				}
				backendCapabilities: ["vcs.writeTree", "vcs.readDiff", "evidence.prepare", "vcs.writeTransaction"]
				rationale: "Bind draft evidence to the staged tree before final commit creation."
			},
			{
				id:          "stack.finalizePatch"
				class:       "finalize"
				agentFacing: true
				requires: {
					activePatch:   true
					cleanWorktree: true
					transaction:   true
					evidence:      true
					approval:      "finalize"
				}
				effects: {
					reads: ["index", "prepared evidence", "patch metadata"]
					writes: ["commit object", "patch metadata", "sealed evidence", "transaction journal"]
					createsCommit: true
					changesRef:    true
				}
				backendCapabilities: ["vcs.writeTree", "vcs.createCommit", "vcs.updateRef", "evidence.seal", "vcs.writeTransaction"]
				transactionPolicy: {
					mode:                "required"
					transactionContract: "#Transaction"
					requiredSnapshotSurfaces: ["head", "refs", "index", "worktree", "untracked", "adapter_artifacts", "operation_input"]
					postflightPredicates: ["patch commit exists", "stack ref updated", "index and worktree policy satisfied", "evidence links commit oid"]
					priorTransactionIDAllowed: false
				}
				rationale: "Create the final commit only after staged-tree evidence has been prepared."
			},
			{
				id:          "stack.push"
				class:       "publish"
				agentFacing: true
				requires: {
					activePatch: true
					transaction: true
					evidence:    true
					commit:      true
					approval:    "finalize"
				}
				effects: {
					reads: ["local ref", "sealed evidence", "remote ref"]
					writes: ["remote ref", "push evidence", "transaction journal"]
					changesRef:   true
					pushesRemote: true
				}
				backendCapabilities: ["vcs.readRefs", "vcs.push", "vcs.verifyRemoteRef", "evidence.record", "vcs.writeTransaction"]
				rationale: "Publish the finalized commit and verify that the remote ref resolves to the same revision before turn completion."
			},
			{
				id:          "stack.compareRevision"
				class:       "read"
				agentFacing: true
				requires: {}
				effects: {
					reads: ["patch metadata", "stack order", "commit graphs", "trees"]
				}
				backendCapabilities: ["vcs.compareRevision"]
				transactionPolicy: {
					mode: "exempt"
					requiredSnapshotSurfaces: []
					postflightPredicates: []
					priorTransactionIDAllowed: false
				}
				rationale: "Compare patch-stack revisions natively by patch identity and tree changes, without git range-diff."
			},
			{
				id:          "stack.rollback"
				class:       "rollback"
				agentFacing: true
				requires: {
					activePatch: true
					transaction: true
					approval:    "rollback"
				}
				effects: {
					reads: ["transaction journal", "patch evidence"]
					writes: ["refs", "index", "worktree", "transaction journal"]
					changesRef:      true
					changesIndex:    true
					changesWorktree: true
				}
				backendCapabilities: ["vcs.restoreRefs", "vcs.restoreIndex", "vcs.restoreWorktree", "vcs.writeTransaction"]
				transactionPolicy: {
					mode:                "rollback_aware"
					transactionContract: "#Transaction"
					requiredSnapshotSurfaces: ["head", "refs", "index", "worktree", "untracked", "conflict_state", "adapter_artifacts"]
					postflightPredicates: ["target transaction restored", "recovery state verified", "rollback evidence emitted"]
					priorTransactionIDAllowed: true
				}
				rationale: "Restore recorded pre-state from the transaction journal while preserving evidence."
			},
			{
				id:          "evidence.prepare"
				class:       "prepare"
				agentFacing: true
				requires: {
					activePatch: true
					transaction: true
				}
				effects: {
					reads: ["staged tree", "patch metadata"]
					writes: ["draft evidence", "transaction journal"]
				}
				backendCapabilities: ["vcs.writeTree", "evidence.prepare", "vcs.writeTransaction"]
				rationale: "Create evidence bound to the staged tree before commit creation."
			},
			{
				id:          "evidence.record"
				class:       "local-mutation"
				agentFacing: true
				requires: {
					activePatch: true
					transaction: true
				}
				effects: {
					writes: ["evidence records", "transaction journal"]
				}
				backendCapabilities: ["evidence.record", "vcs.writeTransaction"]
				rationale: "Append validation results and provenance to the active patch evidence."
			},
			{
				id:          "evidence.seal"
				class:       "finalize"
				agentFacing: true
				requires: {
					activePatch: true
					transaction: true
					evidence:    true
					approval:    "finalize"
				}
				effects: {
					reads: ["commit object", "draft evidence"]
					writes: ["sealed evidence", "transaction journal"]
				}
				backendCapabilities: ["vcs.readCommit", "evidence.seal", "vcs.writeTransaction"]
				rationale: "Seal prepared evidence to the resulting commit without making commit SHA the patch identity."
			},
			{
				id:          "evidence.inspect"
				class:       "read"
				agentFacing: true
				requires: {}
				effects: {
					reads: ["draft evidence", "sealed evidence"]
				}
				backendCapabilities: ["evidence.inspect"]
				rationale: "Inspect evidence records without mutating the patch stack."
			},
		]

		forbidden: [
			{
				namespace: "vcs.*"
				reason:    "Raw VCS capabilities bypass patch-stack transactions, policy, and evidence obligations."
			},
			{
				namespace: "cue.*"
				reason:    "Raw CUE execution is a privileged backend concern, not part of the patch-stack API."
			},
			{
				namespace: "cue_lsp.*"
				reason:    "CUE LSP lifecycle and direct semantic access remain privileged and out of scope."
			},
		]
	}

	privilegedBackends: {
		vcs: {
			capabilities: [
				"vcs.status",
				"vcs.readHead",
				"vcs.readRefs",
				"vcs.readIndex",
				"vcs.readWorktree",
				"vcs.readTree",
				"vcs.readDiff",
				"vcs.readCommit",
				"vcs.writePatchMetadata",
				"vcs.writeTransaction",
				"vcs.checkoutTree",
				"vcs.writeIndex",
				"vcs.writeTree",
				"vcs.createCommit",
				"vcs.updateRef",
				"vcs.push",
				"vcs.verifyRemoteRef",
				"vcs.compareRevision",
				"vcs.restoreRefs",
				"vcs.restoreIndex",
				"vcs.restoreWorktree",
			]
		}
	}

	evidence: {
		subject: "staged-tree"
	}
}
