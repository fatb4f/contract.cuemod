package vcs

#TransactionState:
	"planned" |
	"preflighted" |
	"snapshot_created" |
	"journal_opened" |
	"mutation_started" |
	"mutation_applied" |
	"postflight_started" |
	"committed" |
	"rollback_started" |
	"rolled_back" |
	"rollback_partial" |
	"rollback_failed" |
	"aborted"

#TransactionMode: "exempt" | "required" | "rollback_aware"

#CommandTransactionPolicy: close({
	mode:                 #TransactionMode
	transactionContract?: "#Transaction"
	requiredSnapshotSurfaces: [...#StateSurface]
	postflightPredicates: [...string & !=""]
	priorTransactionIDAllowed: bool

	if mode == "exempt" {
		requiredSnapshotSurfaces: []
		postflightPredicates: []
		priorTransactionIDAllowed: false
	}

	if mode == "required" {
		transactionContract: "#Transaction"
		requiredSnapshotSurfaces: [#StateSurface, ...#StateSurface]
		postflightPredicates: [string & !="", ...(string & !="")]
		priorTransactionIDAllowed: false
	}

	if mode == "rollback_aware" {
		transactionContract: "#Transaction"
		requiredSnapshotSurfaces: [#StateSurface, ...#StateSurface]
		postflightPredicates: [string & !="", ...(string & !="")]
		priorTransactionIDAllowed: true
	}
})

#RollbackClass:
	"none" |
	"ref_only" |
	"index_only" |
	"worktree_only" |
	"ref_index" |
	"ref_index_worktree" |
	"conflict_state" |
	"adapter_artifact" |
	"manual_required"

#FailureClass:
	"preflight_failed" |
	"snapshot_failed" |
	"journal_failed" |
	"mutation_failed" |
	"postflight_failed" |
	"rollback_failed"

#SnapshotCoverage: "complete" | "partial" | "not_required"

#StateSurface:
	"head" |
	"refs" |
	"index" |
	"worktree" |
	"untracked" |
	"conflict_state" |
	"adapter_artifacts" |
	"operation_input"

#JournalPhase:
	"preflight" |
	"snapshot" |
	"journal" |
	"mutation" |
	"postflight" |
	"commit" |
	"rollback" |
	"abort"

#RecoveryPrimitive:
	"restore_ref_snapshot" |
	"consult_reflog" |
	"restore_index_artifact" |
	"apply_worktree_artifact" |
	"restore_untracked_manifest" |
	"preserve_conflict_state" |
	"restore_adapter_artifact" |
	"emit_manual_recovery"

#RollbackPolicy: close({
	class: #RollbackClass
	surfaces: [...#StateSurface]
	requiredSnapshots: [...#StateSurface]
	allowed: [#RecoveryPrimitive, ...#RecoveryPrimitive]
	forbidden: [string & !="", ...(string & !="")]
	reflogSufficient:    bool
	safetyProofRequired: true

	if class != "none" && class != "manual_required" {
		surfaces: [#StateSurface, ...#StateSurface]
		requiredSnapshots: [#StateSurface, ...#StateSurface]
	}

	if class != "ref_only" {
		reflogSufficient: false
	}
})

#RollbackFixture: close({
	name: string & !=""
	repoState: close({
		clean:         bool
		indexDirty:    bool
		worktreeDirty: bool
		untracked:     bool
		conflict:      bool
	})
	failureClass:  #FailureClass
	rollbackClass: #RollbackClass
	snapshotCoverage: [...#StateSurface]
	expectedState:  "aborted" | "rolled_back" | "rollback_partial" | "rollback_failed"
	reflogOnly:     false
	manualRequired: bool

	if failureClass == "preflight_failed" {
		rollbackClass: "none"
		expectedState: "aborted"
	}

	if expectedState == "rollback_partial" || expectedState == "rollback_failed" {
		manualRequired: true
	}

	if rollbackClass == "manual_required" {
		manualRequired: true
	}
})

rollbackPolicies: {
	none: #RollbackPolicy & {
		class: "none"
		surfaces: []
		requiredSnapshots: []
		allowed: ["emit_manual_recovery"]
		forbidden: ["git reset --hard"]
		reflogSufficient: false
	}
	refOnly: #RollbackPolicy & {
		class: "ref_only"
		surfaces: ["head", "refs"]
		requiredSnapshots: ["head", "refs"]
		allowed: ["restore_ref_snapshot", "consult_reflog"]
		forbidden: ["git reset --hard", "restore index without index snapshot", "restore worktree without worktree snapshot"]
		reflogSufficient: true
	}
	indexOnly: #RollbackPolicy & {
		class: "index_only"
		surfaces: ["index"]
		requiredSnapshots: ["index"]
		allowed: ["restore_index_artifact"]
		forbidden: ["git reset --hard", "reflog-only recovery"]
		reflogSufficient: false
	}
	worktreeOnly: #RollbackPolicy & {
		class: "worktree_only"
		surfaces: ["worktree", "untracked"]
		requiredSnapshots: ["worktree", "untracked"]
		allowed: ["apply_worktree_artifact", "restore_untracked_manifest"]
		forbidden: ["git reset --hard", "reflog-only recovery"]
		reflogSufficient: false
	}
	refIndex: #RollbackPolicy & {
		class: "ref_index"
		surfaces: ["head", "refs", "index"]
		requiredSnapshots: ["head", "refs", "index"]
		allowed: ["restore_ref_snapshot", "restore_index_artifact"]
		forbidden: ["git reset --hard", "reflog-only recovery"]
		reflogSufficient: false
	}
	refIndexWorktree: #RollbackPolicy & {
		class: "ref_index_worktree"
		surfaces: ["head", "refs", "index", "worktree", "untracked"]
		requiredSnapshots: ["head", "refs", "index", "worktree", "untracked"]
		allowed: ["restore_ref_snapshot", "restore_index_artifact", "apply_worktree_artifact", "restore_untracked_manifest"]
		forbidden: ["git reset --hard", "reflog-only recovery"]
		reflogSufficient: false
	}
	conflictState: #RollbackPolicy & {
		class: "conflict_state"
		surfaces: ["index", "worktree", "conflict_state"]
		requiredSnapshots: ["index", "worktree", "conflict_state"]
		allowed: ["restore_index_artifact", "apply_worktree_artifact", "preserve_conflict_state"]
		forbidden: ["git reset --hard", "erase conflict diagnostics"]
		reflogSufficient: false
	}
	adapterArtifact: #RollbackPolicy & {
		class: "adapter_artifact"
		surfaces: ["adapter_artifacts"]
		requiredSnapshots: ["adapter_artifacts"]
		allowed: ["restore_adapter_artifact"]
		forbidden: ["git reset --hard", "delete transaction journal"]
		reflogSufficient: false
	}
	manualRequired: #RollbackPolicy & {
		class: "manual_required"
		surfaces: []
		requiredSnapshots: []
		allowed: ["emit_manual_recovery"]
		forbidden: ["git reset --hard", "claim automatic recovery"]
		reflogSufficient: false
	}
}

#EvidenceRef: close({
	transactionID: string & !=""
	kind:          "transaction" | "snapshot" | "journal" | "rollback" | "postflight" | "diagnostic"
	uri:           string & !=""
	immutable:     true
})

#EvidenceRetentionPolicy: close({
	policy:            "transaction_lifetime" | "repository_lifetime" | "manual_release"
	minimumDays:       int & >0
	preserveOnFailure: true
	preserveOnManual:  true
})

#TransactionEvidenceBundle: close({
	transactionID: string & !=""
	let bundleID = transactionID
	transaction: #EvidenceRef & {
		transactionID: bundleID
		kind:          "transaction"
	}
	snapshot: #EvidenceRef & {
		transactionID: bundleID
		kind:          "snapshot"
	}
	journal: #EvidenceRef & {
		transactionID: bundleID
		kind:          "journal"
	}
	postflight?: #EvidenceRef & {
		transactionID: bundleID
		kind:          "postflight"
	}
	rollback?: #EvidenceRef & {
		transactionID: bundleID
		kind:          "rollback"
	}
	diagnostic?: #EvidenceRef & {
		transactionID: bundleID
		kind:          "diagnostic"
	}
	retention: #EvidenceRetentionPolicy
})

#ExpectedStatePredicate: close({
	name:     string & !=""
	surface:  #StateSurface
	expected: string & !=""
	actual:   string & !=""
	pass:     bool
	evidence: [#EvidenceRef, ...#EvidenceRef]
})

#Postflight: close({
	validator: close({
		id:      string & !=""
		command: string & =~"^stack\\."
	})
	started:   true
	completed: bool
	allPass:   bool
	predicates: [#ExpectedStatePredicate, ...#ExpectedStatePredicate]
	evidence: [#EvidenceRef, ...#EvidenceRef]

	if allPass {
		completed: true
	}
})

#PreflightGuard: close({
	name:    string & !=""
	pass:    bool
	reason?: string & !=""
})

#Preflight: close({
	observed: close({
		headOID:              string & =~"^[0-9a-f]{40}$"
		headRef?:             string & =~"^refs/"
		indexDirty:           bool
		worktreeDirty:        bool
		untrackedPresent:     bool
		conflictStatePresent: bool
		relevantRefs: [...string & =~"^refs/"] | *[]
		adapterArtifacts: [...string & !=""] | *[]
	})

	cleanliness: close({
		headKnown:        bool
		indexReadable:    bool
		worktreeReadable: bool
		untrackedPolicy:  "preserve" | "block" | "capture"
	})

	guards: [#PreflightGuard, ...#PreflightGuard]
})

#RefSnapshot: close({
	name: string & =~"^refs/"
	oid:  string & =~"^[0-9a-f]{40}$"
})

#Snapshot: close({
	status: "complete" | "partial"

	head: close({
		coverage: #SnapshotCoverage
		oid:      string & =~"^[0-9a-f]{40}$"
		ref?:     string & =~"^refs/"
	})

	index: close({
		coverage:  #SnapshotCoverage
		captured:  bool
		format:    "patch" | "tree" | "adapter_artifact" | "not_required"
		artifact?: string & !=""
	})

	worktree: close({
		coverage:        #SnapshotCoverage
		captured:        bool
		format:          "patch" | "tree" | "adapter_artifact" | "not_required"
		artifact?:       string & !=""
		untrackedPolicy: "preserve" | "block" | "capture"
		untracked: [...string & !=""] | *[]
	})

	refs: close({
		coverage: #SnapshotCoverage
		values: [...#RefSnapshot] | *[]
	})

	conflictState: close({
		coverage:  #SnapshotCoverage
		captured:  bool
		artifact?: string & !=""
	})

	adapterArtifacts: close({
		coverage: #SnapshotCoverage
		artifacts: [...string & !=""] | *[]
	})

	operationInput: close({
		coverage: #SnapshotCoverage
		artifact: string & !=""
	})

	surfaces: [#StateSurface, ...#StateSurface]
})

#JournalEntry: close({
	transactionID:  string & !=""
	seq:            int & >=0
	phase:          #JournalPhase
	action:         string & !=""
	target?:        string & !=""
	before?:        string & !=""
	after?:         string & !=""
	rollbackClass?: #RollbackClass
	evidence: [...#EvidenceRef] | *[]
	timestamp?: string & !=""
})

#MutationJournal: close({
	transactionID:        string & !=""
	appendOnly:           true
	sequenceContiguous:   true
	recordsBeforeAfter:   true
	recordsRollbackClass: true
	phaseCoverage: [#JournalPhase, ...#JournalPhase]

	let journalID = transactionID
	entries: [#JournalEntry & {transactionID: journalID}, ...(#JournalEntry & {transactionID: journalID})]
})

#RecoveryReport: close({
	state:          #TransactionState
	recovered:      bool
	manualRequired: bool
	notes: [...string & !=""] | *[]
	evidence: [#EvidenceRef, ...#EvidenceRef]
})

#TransactionResult: close({
	ok:            bool
	failureClass?: #FailureClass
	rollbackClass: #RollbackClass | *"none"
	recovery?:     #RecoveryReport
	evidence: [#EvidenceRef, ...#EvidenceRef]
	evidenceBundle: #TransactionEvidenceBundle

	if rollbackClass == "manual_required" {
		recovery: {
			manualRequired: true
			evidence: [#EvidenceRef & {kind: "diagnostic"}, ...#EvidenceRef]
		}
		evidenceBundle: diagnostic: #EvidenceRef
	}
})

#Transaction: close({
	id:      string & !=""
	command: string & =~"^stack\\."
	state:   #TransactionState

	repo: close({
		root:    string & !=""
		head:    string & =~"^[0-9a-f]{40}$"
		branch?: string & !=""
	})

	preflight: #Preflight
	snapshot:  #Snapshot
	journal: #MutationJournal & {
		transactionID: id
	}
	postflight?: #Postflight & {
		validator: command: command
	}

	result?: #TransactionResult & {
		evidenceBundle: transactionID: id
	}

	if state == "committed" {
		postflight: {
			completed: true
			allPass:   true
		}
		result: {
			ok: true
			evidence: [#EvidenceRef & {kind: "postflight"}, ...#EvidenceRef]
			evidenceBundle: postflight: #EvidenceRef
		}
	}

	if state == "rollback_started" || state == "rolled_back" || state == "rollback_partial" || state == "rollback_failed" {
		result: {
			ok:            false
			failureClass:  "mutation_failed" | "postflight_failed" | "rollback_failed"
			rollbackClass: #RollbackClass & !="none"
			recovery: evidence: [#EvidenceRef & {kind: "rollback"}, ...#EvidenceRef]
			evidenceBundle: rollback: #EvidenceRef
		}
	}

})
