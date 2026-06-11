# VCS Stack Transaction And Rollback Contract

The normative contract is
[`contracts/vcs/transaction.cue`](../contracts/vcs/transaction.cue). It applies
to every `stack.*` operation that can mutate refs, HEAD, the index, the
worktree, conflict state, or adapter-owned artifacts.

```text
stack mutation intent
  -> transaction preflight
  -> recoverable snapshot
  -> append-only mutation journal
  -> guarded mutation
  -> postflight validation
  -> commit | rollback | degraded recovery
```

No stack mutation may modify Git state before its preflight snapshot exists
and its mutation journal is open.

## Transaction Lifecycle

The successful state machine is:

```text
planned
  -> preflighted
  -> snapshot_created
  -> journal_opened
  -> mutation_started
  -> mutation_applied
  -> postflight_started
  -> committed
```

Commit means that the mutation was applied, every expected-state predicate
passed, and the transaction result links the required evidence. Applying the
mutation alone is not commit.

Mutation or postflight failure follows this state machine:

```text
mutation_started | mutation_applied | postflight_started
  -> rollback_started
  -> rolled_back | rollback_partial | rollback_failed
```

A mutation failure means an intended write did not complete. A postflight
failure means writes occurred, but the resulting repository state could not
be proved to match the command contract. Both require rollback
classification. Postflight failure is never converted into success merely
because the underlying write returned no error.

Pre-mutation failure follows the abort path:

```text
planned | preflighted | snapshot_created
  -> aborted
```

Abort and rollback are distinct. Abort records that no guarded mutation
started. Rollback records an attempted restoration after mutation started.
An opened journal that cannot safely begin mutation is also closed as
`aborted`, with diagnostic evidence.

## Degraded Recovery

`rolled_back` means every affected surface was restored and verified.
`rollback_partial` means some surfaces were restored but complete recovery
could not be proved. `rollback_failed` means the selected recovery procedure
failed. Partial or failed rollback sets `manualRequired: true`, preserves all
diagnostic artifacts, and must not report transaction success.

Rollback selection is based on the affected state surfaces and failure class.
A generic reset is not a transaction recovery policy.

## Rollback Classes

The contract maps each rollback class to its affected surfaces, required
snapshots, allowed recovery primitives, and forbidden recovery primitives:

| Class | Required recovery surface |
| --- | --- |
| `ref_only` | HEAD and relevant refs |
| `index_only` | index |
| `worktree_only` | tracked worktree state and untracked manifest |
| `ref_index` | refs and index |
| `ref_index_worktree` | refs, index, worktree, and untracked files |
| `conflict_state` | index, worktree, and operation conflict state |
| `adapter_artifact` | adapter-owned transaction and evidence artifacts |
| `manual_required` | no automatic recovery can be proved safe |

Reflog is useful evidence, not a sufficient rollback substrate. It can help
recover ref movement, but it does not capture index state, unstaged worktree
changes, untracked files, conflict state, transaction intent, mutation phase,
or adapter-owned evidence.

Any rollback that relies only on reflog is rejected unless its class is
explicitly `ref_only`. Even for `ref_only`, the recorded ref snapshot is the
primary recovery source and reflog is supporting evidence.

`git reset --hard` is forbidden as a generic recovery primitive. It can
destroy user worktree changes, erase index intent, and discard conflict state
that is required for diagnosis. Missing or partial required snapshots select
`manual_required`; they do not justify a destructive reset.

## Go Adapter Projection

The normative Go-facing projection is
[`contracts/vcs/transaction_adapter.cue`](../contracts/vcs/transaction_adapter.cue).
It exposes only guarded transaction lifecycle methods:

```go
type Transaction interface {
	ID() string
	State() TransactionState

	Preflight(ctx context.Context) error
	Snapshot(ctx context.Context) (Snapshot, error)
	Journal(ctx context.Context, entry JournalEntry) error

	Apply(ctx context.Context, mutation Mutation) error
	Postflight(ctx context.Context, validator Validator) error

	Commit(ctx context.Context) error
	Rollback(ctx context.Context, failure error) (*RecoveryReport, error)
}
```

The adapter also classifies errors into `FailureClass` and `RollbackClass`.
It does not expose direct stack mutation methods that bypass preflight,
snapshot, journal, postflight, or rollback classification.

## Fixture Model

`fixtures/vcs/valid/rollback_fixtures.cue` lists contract fixtures for clean
preflight abort, dirty index, dirty worktree, untracked files, ref mutation
failure, combined ref/index failure, full stack rewrite, patch-apply conflict,
adapter artifact failure, postflight failure, and rollback failure. Together
they cover every rollback class and degraded recovery.

`fixtures/vcs/invalid-reflog-only/rollback.cue` proves that reflog-only
recovery cannot validate for an index rollback. `test/check.sh` requires that
fixture to fail. `fixtures/vcs/invalid-missing-transaction-policy` similarly
proves that a stack mutator cannot validate without a transaction policy.

## Transactional Staging

The `stack_stage` MCP tool implements `stack.stage` as an index-only
transaction. Requests identify the active patch and list exact
repository-relative paths. An optional unified patch selects hunks while still
constraining the resulting index delta to those paths.

Before mutation, the runner records the current index tree, the complete
worktree diff against `HEAD`, untracked paths, refs, and serialized operation
input. Postflight requires an index delta, rejects changes outside the selected
paths, and proves that tracked worktree content and untracked paths were
preserved. Mutation or postflight failure restores the recorded index tree with
an `index_only` rollback and emits rollback and diagnostic evidence.

## Transactional Patch Finalization

The `stack_finalize_patch` MCP tool converts an already staged tree into an
immutable patch commit without moving `HEAD`. It derives the stable stack ref
`refs/stack/patches/<patch-id>`, creates the commit with `HEAD` as its parent,
updates that ref with compare-and-swap semantics, and writes sealed patch
metadata under `.git/git-mcp-patches`.

Finalization aborts before mutation when the index is empty, the worktree has
unstaged changes, or a merge, cherry-pick, revert, or rebase conflict state is
active. It also requires the tree OID recorded by prepared evidence to equal the
current staged tree. Postflight verifies the commit object, stack ref, unchanged
index and worktree, preserved untracked paths, and the metadata link between
patch identity, commit identity, and prepared evidence.

The transaction snapshots the previous stack ref and metadata artifact.
Mutation or postflight failure restores the prior ref and metadata, or deletes
newly created state, while retaining the immutable commit object for diagnosis.

## Transactional Rollback

The `stack_rollback` MCP tool selects a committed target by transaction ID,
loads its immutable transaction, snapshot, journal, and operation evidence, and
requires the caller's rollback class to match the class declared by that
evidence. The active patch identity must also match the recorded stage or
finalize operation. Successful mutations seal a postflight index, worktree,
untracked-path, and relevant-ref fingerprint; rollback refuses to proceed when
the current repository no longer matches that recorded post-state.

Current stack mutations provide two executable recovery classes:

- `index_only` restores the index tree captured before `stack.stage`. It first
  rejects any later staged changes outside the paths recorded by that stage
  operation.
- `ref_only` restores or deletes the stack ref and restores or removes patch
  metadata captured before `stack.finalizePatch`. It first proves that the
  current ref and metadata still describe the finalized patch.

Other rollback classes produce `rollback_partial` with
`manualRequired: true`; they do not fall back to reset or reflog behavior.
Every attempt writes a separate rollback journal and immutable transaction,
rollback, and recovery evidence under `.git/git-mcp-transactions/<tx-id>`.
