package valid

import "github.com/fatb4f/contract.cuemod/contracts/vcs"

transaction: vcs.#Transaction & {
	id:      "txn-20260611-0001"
	command: "stack.stage"
	state:   "committed"

	repo: {
		root:   "/workspace"
		head:   "0123456789abcdef0123456789abcdef01234567"
		branch: "main"
	}

	preflight: {
		observed: {
			headOID:              "0123456789abcdef0123456789abcdef01234567"
			headRef:              "refs/heads/main"
			indexDirty:           false
			worktreeDirty:        true
			untrackedPresent:     false
			conflictStatePresent: false
			relevantRefs: ["refs/heads/main"]
		}
		cleanliness: {
			headKnown:        true
			indexReadable:    true
			worktreeReadable: true
			untrackedPolicy:  "preserve"
		}
		guards: [{
			name: "repository-readable"
			pass: true
		}]
	}

	snapshot: {
		status: "complete"
		head: {
			coverage: "complete"
			oid:      "0123456789abcdef0123456789abcdef01234567"
			ref:      "refs/heads/main"
		}
		index: {
			captured: true
			coverage: "complete"
			format:   "tree"
			artifact: "artifact://transactions/txn-20260611-0001/index"
		}
		worktree: {
			captured:        true
			coverage:        "complete"
			format:          "patch"
			artifact:        "artifact://transactions/txn-20260611-0001/worktree.patch"
			untrackedPolicy: "preserve"
		}
		refs: {
			coverage: "complete"
			values: [{
				name: "refs/heads/main"
				oid:  "0123456789abcdef0123456789abcdef01234567"
			}]
		}
		conflictState: {
			coverage: "not_required"
			captured: false
		}
		adapterArtifacts: {
			coverage: "not_required"
		}
		operationInput: {
			coverage: "complete"
			artifact: "artifact://transactions/txn-20260611-0001/input"
		}
		surfaces: ["head", "refs", "index", "worktree", "operation_input"]
	}

	journal: {
		transactionID:        "txn-20260611-0001"
		appendOnly:           true
		sequenceContiguous:   true
		recordsBeforeAfter:   true
		recordsRollbackClass: true
		phaseCoverage: ["preflight", "snapshot", "journal", "mutation", "postflight", "commit"]
		entries: [
			{
				transactionID: "txn-20260611-0001"
				seq:           0
				phase:         "preflight"
				action:        "guards_passed"
			},
			{
				transactionID: "txn-20260611-0001"
				seq:           1
				phase:         "snapshot"
				action:        "captured"
				evidence: [{
					transactionID: "txn-20260611-0001"
					kind:          "snapshot"
					uri:           "artifact://transactions/txn-20260611-0001/snapshot"
					immutable:     true
				}]
			},
			{
				transactionID: "txn-20260611-0001"
				seq:           2
				phase:         "journal"
				action:        "opened"
			},
			{
				transactionID: "txn-20260611-0001"
				seq:           3
				phase:         "mutation"
				action:        "write_index"
				target:        "index"
				before:        "tree:before"
				after:         "tree:after"
			},
			{
				transactionID: "txn-20260611-0001"
				seq:           4
				phase:         "postflight"
				action:        "validated"
			},
			{
				transactionID: "txn-20260611-0001"
				seq:           5
				phase:         "commit"
				action:        "committed"
			},
		]
	}

	postflight: {
		validator: {
			id:      "stack.stage/v1"
			command: "stack.stage"
		}
		started:   true
		completed: true
		allPass:   true
		predicates: [
			{
				name:     "selected-paths-staged"
				surface:  "index"
				expected: "tree:after"
				actual:   "tree:after"
				pass:     true
				evidence: [{
					transactionID: "txn-20260611-0001"
					kind:          "postflight"
					uri:           "artifact://transactions/txn-20260611-0001/postflight/index"
					immutable:     true
				}]
			},
			{
				name:     "worktree-preserved"
				surface:  "worktree"
				expected: "artifact://transactions/txn-20260611-0001/worktree.patch"
				actual:   "artifact://transactions/txn-20260611-0001/worktree.patch"
				pass:     true
				evidence: [{
					transactionID: "txn-20260611-0001"
					kind:          "postflight"
					uri:           "artifact://transactions/txn-20260611-0001/postflight/worktree"
					immutable:     true
				}]
			},
		]
		evidence: [{
			transactionID: "txn-20260611-0001"
			kind:          "postflight"
			uri:           "artifact://transactions/txn-20260611-0001/postflight"
			immutable:     true
		}]
	}

	result: {
		ok: true
		evidence: [{
			transactionID: "txn-20260611-0001"
			kind:          "postflight"
			uri:           "artifact://transactions/txn-20260611-0001/postflight"
			immutable:     true
		}, {
			transactionID: "txn-20260611-0001"
			kind:          "transaction"
			uri:           "artifact://transactions/txn-20260611-0001/result"
			immutable:     true
		}]
		evidenceBundle: {
			transactionID: "txn-20260611-0001"
			transaction: {
				transactionID: "txn-20260611-0001"
				kind:          "transaction"
				uri:           "artifact://transactions/txn-20260611-0001/result"
				immutable:     true
			}
			snapshot: {
				transactionID: "txn-20260611-0001"
				kind:          "snapshot"
				uri:           "artifact://transactions/txn-20260611-0001/snapshot"
				immutable:     true
			}
			journal: {
				transactionID: "txn-20260611-0001"
				kind:          "journal"
				uri:           "artifact://transactions/txn-20260611-0001/journal"
				immutable:     true
			}
			postflight: {
				transactionID: "txn-20260611-0001"
				kind:          "postflight"
				uri:           "artifact://transactions/txn-20260611-0001/postflight"
				immutable:     true
			}
			retention: {
				policy:            "repository_lifetime"
				minimumDays:       30
				preserveOnFailure: true
				preserveOnManual:  true
			}
		}
	}
}
