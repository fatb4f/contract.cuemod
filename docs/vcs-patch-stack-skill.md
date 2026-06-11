# VCS Patch-Stack Skill Contract

The VCS patch-stack skill is the agent-facing boundary above the privileged
VCS and evidence backends:

```text
agent intent
  -> stack.* / evidence.*
  -> patch-stack policy and transactions
  -> privileged go-git adapter
  -> Git object state
```

The normative contract is
[`contract/vcs/patch_stack_skill.cue`](../contract/vcs/patch_stack_skill.cue).

## Public API

Agents may use these operations:

```text
stack.status
stack.startPatch
stack.activatePatch
stack.stage
stack.prepareEvidence
stack.finalizePatch
stack.push
stack.compareRevision
stack.rollback

evidence.prepare
evidence.record
evidence.seal
evidence.inspect
```

The operation contract declares each operation's class, preconditions,
observable effects, approval level, backend capability mapping, and rationale.
Read operations do not require a transaction. Operations that write patch,
Git, transaction, or evidence state require a transaction. Content mutations,
finalization, and rollback require an active patch.

`stack.startPatch` is a preparation operation: it creates the stable patch
identity, appends it to explicit stack order, and establishes the transaction
context used by later mutations.

## Turn Completion

A mutation turn cannot complete after editing or local validation alone. The
contract requires this ordered closeout:

```text
stack.stage
  -> stack.prepareEvidence
  -> stack.finalizePatch
  -> stack.push
```

The completion record is valid only when staging completed, evidence was
prepared and sealed, a commit was created, that exact commit was pushed, and
the remote ref was read back and verified. The worktree and index must be
clean, and both local and remote refs must resolve to the finalized commit.

Failure to stage, commit, push, or verify the remote leaves the mutation turn
open. It is not a successful turn-end state.

## Privileged Boundary

Raw `vcs.*`, `cue.*`, and `cue_lsp.*` capabilities are internal and
privileged. They are not an alternate public API.

The core VCS adapter is `go-git`, including push and remote-ref verification.
Git CLI fallback is forbidden in that
adapter because shell behavior would bypass the declared capability mapping,
transaction journal, and evidence policy.

## Identity And Comparison

A patch has a stable identity independent of commit SHA. Finalization may
associate a commit with the patch, but rewriting or re-finalizing the patch
does not change its identity.

Stack order is explicit metadata. `stack.compareRevision` compares revisions
natively using patch identities, stack order, commit graphs, and tree changes.
It does not delegate to `git range-diff`.

## Evidence And Finalization

Evidence is prepared against the staged tree before final commit creation.
Finalization requires prepared evidence and a clean worktree, then creates the
commit, updates the ref, and seals evidence to the resulting commit.

Sealing a commit association does not make commit SHA the patch identity.
Evidence records are immutable after sealing.

## Rollback

Every mutation records pre-state and post-state in a transaction journal.
Rollback restores refs, index, and worktree from that journal while preserving
the evidence trail. Reflog recovery alone is not sufficient.
