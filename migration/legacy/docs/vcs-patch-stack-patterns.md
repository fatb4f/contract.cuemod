
## VCS patch stack use case patterns

A **VCS patch stack** is the stack that answers:

```text
Given a dirty repo, intended change, validation rules, and commit policy,
how should changes be segmented, staged, validated, finalized, rolled back, and audited?
```

It converts unstructured edits into a controlled sequence of patch units with explicit state transitions.

Typical components:

```text
working tree
→ index
→ HEAD / refs
→ branch / upstream
→ diff parser
→ hunk model
→ patch unit model
→ dependency/order graph
→ validation gates
→ staging transaction
→ commit/finalize adapter
→ rollback/recovery model
→ evidence ledger
→ agent / MCP VCS adapter
```

The patch stack is not just “git add && git commit.” It is a control surface for safe mutation.

---

# 1. Repository state snapshot

| Field                  | Description                                                                                                                 |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “What is the current VCS state before acting?”                                                                              |
| **Conceptual problem** | Patch operations are unsafe without a stable view of branch, HEAD, index, working tree, untracked files, and ignored files. |
| **Solution**           | Capture a normalized repo snapshot before each mutation phase.                                                              |
| **Typical tools**      | Git status, git diff, git rev-parse, go-git, Git MCP, custom VCS adapter.                                                   |
| **Relates to**         | Staging, rollback, conflict detection, evidence tracking.                                                                   |

**Pattern**

```text
repo root
→ read HEAD + branch + index + working tree
→ VCS snapshot
```

**Example**

```text
branch = main
HEAD = 5f22647
staged = none
unstaged = internal/vcs/stack.go modified
untracked = docs/vcs-patch-stack.md
```

Snapshot is the state estimator input.

---

# 2. Dirty-state classification

| Field                  | Description                                                                                                 |
| ---------------------- | ----------------------------------------------------------------------------------------------------------- |
| **Use case**           | “What kinds of changes exist?”                                                                              |
| **Conceptual problem** | Modified, deleted, renamed, untracked, conflicted, generated, and ignored files require different handling. |
| **Solution**           | Classify working tree and index entries into typed change categories.                                       |
| **Typical tools**      | Git porcelain v2, diff name-status, status adapters.                                                        |
| **Relates to**         | Patch segmentation, safety gates, rollback.                                                                 |

**Pattern**

```text
status entries
→ classify by state
→ patch candidate set
```

**Change classes**

| Class        | Meaning                            |
| ------------ | ---------------------------------- |
| `modified`   | tracked file changed               |
| `added`      | new tracked or untracked candidate |
| `deleted`    | tracked file removed               |
| `renamed`    | path identity changed              |
| `conflicted` | merge/rebase conflict              |
| `generated`  | derived artifact                   |
| `ignored`    | outside managed patch surface      |

Dirty-state classification prevents accidental commits.

---

# 3. Diff parsing

| Field                  | Description                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------------- |
| **Use case**           | “What exactly changed?”                                                                           |
| **Conceptual problem** | File-level status is too coarse; patch units usually live at hunk or semantic-region granularity. |
| **Solution**           | Parse diffs into files, hunks, line ranges, modes, and metadata.                                  |
| **Typical tools**      | `git diff --patch`, go-diff, git plumbing, parser libraries.                                      |
| **Relates to**         | Hunk staging, patch segmentation, review projection.                                              |

**Pattern**

```text
working tree/index diff
→ file diffs
→ hunks
→ patch atoms
```

**Example**

```text
file = internal/patchplan/adapter.go
hunk = lines 42-88
change = add PatchplanAdapter interface
```

Diff parsing is the sensor layer for patch planning.

---

# 4. Semantic patch segmentation

| Field                  | Description                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------------ |
| **Use case**           | “Which changes belong together?”                                                                 |
| **Conceptual problem** | A dirty working tree may contain several logical changes mixed across files and hunks.           |
| **Solution**           | Group hunks into patch units by objective, symbol, contract, test, generated artifact, or issue. |
| **Typical tools**      | Diff parser, code-intel graph, issue metadata, contract graph, manual labels.                    |
| **Relates to**         | Commit planning, staging, validation, review.                                                    |

**Pattern**

```text
hunks + symbols + contracts
→ logical patch units
→ ordered stack
```

**Example units**

```text
patch 1: add adapter contract types
patch 2: wire demo/validate tool execution
patch 3: add rejection semantics tests
```

Segmentation is where raw changes become an intentional stack.

---

# 5. Patch unit contract

| Field                  | Description                                                                                                                |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “What must this patch contain and prove?”                                                                                  |
| **Conceptual problem** | A patch without an explicit contract can drift into unrelated changes.                                                     |
| **Solution**           | Give each patch unit a rationale, scope, touched paths, expected validation, rollback strategy, and evidence requirements. |
| **Typical tools**      | CUE patch schema, issue template, commit plan, test plan.                                                                  |
| **Relates to**         | Staging transaction, validation, commit finalization.                                                                      |

**Pattern**

```text
logical patch
→ patch contract
→ bounded staging and validation
```

**Contract shape**

```cue
#PatchUnit: {
	id: string
	rationale: string
	scope: [...string]
	paths: [...string]
	allowedHunks: [...string]
	validators: [...string]
	rollback: [...string]
	evidence: [...string]
}
```

Patch unit contracts are the authority model for staging.

---

# 6. Patch dependency ordering

| Field                  | Description                                                                                                             |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “Which patch must come first?”                                                                                          |
| **Conceptual problem** | Patches often depend on types, interfaces, tests, generated artifacts, or config changes introduced by earlier patches. |
| **Solution**           | Build a dependency graph among patch units.                                                                             |
| **Typical tools**      | Contract graph, code-intel references, test mapping, build graph.                                                       |
| **Relates to**         | Stack planning, validation order, rollback.                                                                             |

**Pattern**

```text
patch units
→ dependency edges
→ topological order
→ stack plan
```

**Example**

```text
adapter interface
→ command execution wrapper
→ MCP tool registration
→ acceptance tests
```

Dependency ordering keeps the stack replayable.

---

# 7. Staging transaction

| Field                  | Description                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------------- |
| **Use case**           | “Stage exactly this patch and nothing else.”                                                 |
| **Conceptual problem** | Git index mutation is stateful; partial staging can accidentally include unrelated hunks.    |
| **Solution**           | Snapshot index, stage declared paths/hunks, validate staged diff, rollback index on failure. |
| **Typical tools**      | Git index, `git add -p`, `git apply --cached`, custom hunk staging, Git MCP.                 |
| **Relates to**         | Patch unit contract, rollback, commit finalization.                                          |

**Pattern**

```text
index snapshot
→ apply staged hunks
→ compare staged diff to patch contract
→ commit or rollback
```

**Invariant**

```text
staged diff must be subset of patch unit contract
```

Staging is a transaction, not a side effect.

---

# 8. Index rollback

| Field                  | Description                                                                               |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Use case**           | “Undo failed staging without losing working tree changes.”                                |
| **Conceptual problem** | Failed staging should not destroy user edits or leave mixed index state.                  |
| **Solution**           | Restore the index to the pre-transaction snapshot while preserving working tree contents. |
| **Typical tools**      | `git reset`, index tree snapshot, temporary index, Git plumbing.                          |
| **Relates to**         | Staging transaction, failure handling, evidence.                                          |

**Pattern**

```text
pre-stage index snapshot
→ failed validation
→ restore index
→ report preserved working tree
```

**Important distinction**

```text
rollback index ≠ discard working tree
```

Index rollback is the safety boundary for partial staging.

---

# 9. Worktree safety guard

| Field                  | Description                                                                    |
| ---------------------- | ------------------------------------------------------------------------------ |
| **Use case**           | “Prevent accidental source mutation.”                                          |
| **Conceptual problem** | Patch tooling may run formatters, generators, or validators that mutate files. |
| **Solution**           | Declare allowed write scopes and verify post-action diff against the contract. |
| **Typical tools**      | Git diff, filesystem guards, CUE policy, sandbox wrappers.                     |
| **Relates to**         | Validation, generated artifacts, rollback.                                     |

**Pattern**

```text
allowed write set
→ run operation
→ inspect resulting diff
→ accept / reject / rollback
```

**Example**

```text
Allowed:
  patchplan/out/**

Denied:
  production source
  unrelated config
  credentials
```

Worktree safety guards bound mutation.

---

# 10. Generated artifact handling

| Field                  | Description                                                                                             |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Use case**           | “Should generated files be staged?”                                                                     |
| **Conceptual problem** | Generated artifacts may be required, stale, intentionally ignored, or reproducible and unstaged.        |
| **Solution**           | Classify generated outputs and define whether they are committed, ignored, or exposed as evidence only. |
| **Typical tools**      | Code generators, CUE export, patchplan outputs, source maps, `.gitignore`.                              |
| **Relates to**         | Evidence, freshness, validation, MCP resources.                                                         |

**Pattern**

```text
source change
→ generator output
→ artifact policy
→ stage / ignore / expose as evidence
```

**Artifact policy**

| Policy      | Meaning                                                 |
| ----------- | ------------------------------------------------------- |
| `committed` | artifact is part of repo state                          |
| `ignored`   | artifact is reproducible and not committed              |
| `evidence`  | artifact proves validation but is not production source |
| `transient` | artifact is temporary and discarded                     |

Generated artifacts must never be silently mixed into source patches.

---

# 11. Validation gate

| Field                  | Description                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Use case**           | “Does this patch satisfy its contract?”                                                    |
| **Conceptual problem** | A patch may compile but violate policy, or satisfy schema but fail runtime behavior.       |
| **Solution**           | Run declared validators for the patch unit and collect normalized diagnostics/evidence.    |
| **Typical tools**      | `go test`, `cue vet`, `cue export`, `stylua`, `nvim --headless`, `wezterm`, custom probes. |
| **Relates to**         | Commit finalization, evidence ledger, rollback.                                            |

**Pattern**

```text
staged patch
→ validators
→ normalized results
→ pass / fail / blocked
```

**Validation layers**

| Layer       | Example                            |
| ----------- | ---------------------------------- |
| Syntax      | formatter/parser passes            |
| Type        | compiler/LSP passes                |
| Contract    | CUE validation passes              |
| Runtime     | smoke probe passes                 |
| Integration | MCP tool result matches schema     |
| VCS         | staged diff matches patch contract |

Validation gates close the feedback loop.

---

# 12. Candidate rejection semantics

| Field                  | Description                                                                                        |
| ---------------------- | -------------------------------------------------------------------------------------------------- |
| **Use case**           | “Did the adapter fail, or did the candidate correctly fail validation?”                            |
| **Conceptual problem** | Rejected patches are valid outputs of validation workflows; they should not always be tool errors. |
| **Solution**           | Separate process/adapter failure from candidate acceptance.                                        |
| **Typical tools**      | Patchplan report, normalized result schema, MCP error model.                                       |
| **Relates to**         | Validation, evidence, agent feedback.                                                              |

**Pattern**

```text
tool call executed
→ report parsed
→ accepted = true/false
→ error only if adapter/process/artifact failed
```

**Rule**

```text
accepted=false
  means candidate rejected.

error != nil
  means adapter/process/artifact resolution failed.
```

This distinction is essential for agent-operable validation.

---

# 13. Commit finalization

| Field                  | Description                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------------- |
| **Use case**           | “Turn a validated staged patch into a commit.”                                                  |
| **Conceptual problem** | A commit should represent exactly one validated patch unit with traceable evidence.             |
| **Solution**           | Verify staged diff, run final validators, generate commit message, commit, and record evidence. |
| **Typical tools**      | Git commit, conventional commits, issue tracker, evidence ledger.                               |
| **Relates to**         | Staging transaction, validation, stack progression.                                             |

**Pattern**

```text
validated staged patch
→ final diff check
→ commit message
→ commit object
→ evidence record
```

**Invariant**

```text
commit diff = validated staged patch
```

Commit finalization should never silently include extra staged changes.

---

# 14. Commit message synthesis

| Field                  | Description                                                                              |
| ---------------------- | ---------------------------------------------------------------------------------------- |
| **Use case**           | “What should the commit say?”                                                            |
| **Conceptual problem** | Commit messages should reflect patch intent, scope, evidence, and constraints.           |
| **Solution**           | Generate from patch unit contract, changed files, validation results, and issue linkage. |
| **Typical tools**      | Conventional commits, issue template, diff summary, validation report.                   |
| **Relates to**         | Commit finalization, audit, review projection.                                           |

**Pattern**

```text
patch contract + staged diff + evidence
→ commit subject/body
```

**Example**

```text
feat(mcp): add patchplan adapter contracts and resources

- add request/result types
- add static resource registry
- guard URI-to-path resolution
- add resource mapping tests
```

Commit messages are projections of patch contracts.

---

# 15. Stack progression

| Field                  | Description                                                                                          |
| ---------------------- | ---------------------------------------------------------------------------------------------------- |
| **Use case**           | “Move from one patch unit to the next.”                                                              |
| **Conceptual problem** | Multi-commit work needs clear phase boundaries and dependency tracking.                              |
| **Solution**           | Maintain a stack plan with current patch, completed patches, blocked patches, and remaining patches. |
| **Typical tools**      | Issue checklist, CUE stack model, Git log, branch metadata.                                          |
| **Relates to**         | Dependency ordering, validation, evidence.                                                           |

**Pattern**

```text
stack plan
→ current patch
→ stage/validate/commit
→ mark complete
→ next patch
```

**Example**

```text
1. contracts/resources
2. demo/validate execution
3. rejection semantics coverage
```

Stack progression makes large changes small and auditable.

---

# 16. Conflict detection

| Field                  | Description                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “Will this patch conflict with branch state or another patch?”                                                   |
| **Conceptual problem** | Conflicts may appear at file, hunk, symbol, contract, or dependency level.                                       |
| **Solution**           | Detect conflicting paths, overlapping hunks, changed base commits, unresolved merge markers, and failed replays. |
| **Typical tools**      | Git merge-tree, rebase, diff3, code-intel graph, parser checks.                                                  |
| **Relates to**         | Rebase, rollback, validation.                                                                                    |

**Pattern**

```text
patch unit + base state
→ conflict checks
→ clean / conflict / needs rebase
```

**Conflict layers**

| Layer     | Example                                     |
| --------- | ------------------------------------------- |
| Text      | same lines changed                          |
| File      | deleted/renamed path                        |
| Symbol    | renamed interface used by patch             |
| Contract  | schema changed under patch                  |
| Generated | generated artifact no longer matches source |

Conflict detection should run before destructive operations.

---

# 17. Rebase / replay

| Field                  | Description                                                                       |
| ---------------------- | --------------------------------------------------------------------------------- |
| **Use case**           | “Can this patch stack be replayed on a new base?”                                 |
| **Conceptual problem** | Branches move; patch units need to remain valid across base changes.              |
| **Solution**           | Replay patch units in order, validating after each unit and stopping on conflict. |
| **Typical tools**      | Git rebase, cherry-pick, patch files, stack metadata, validation runner.          |
| **Relates to**         | Dependency ordering, conflict detection, validation.                              |

**Pattern**

```text
new base
→ replay patch 1
→ validate
→ replay patch 2
→ validate
→ stop on conflict/failure
```

Replay tests stack quality.

---

# 18. Review projection

| Field                  | Description                                                                                                       |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “How should humans or agents review this patch?”                                                                  |
| **Conceptual problem** | Raw diffs are noisy; reviewers need rationale, scope, risk, and validation evidence.                              |
| **Solution**           | Project patch unit into review summary, touched paths, semantic changes, validation results, and known non-goals. |
| **Typical tools**      | Diff summary, code-intel graph, evidence ledger, PR template.                                                     |
| **Relates to**         | Commit finalization, evidence, agent review.                                                                      |

**Pattern**

```text
patch unit + diff + evidence
→ review packet
```

**Review packet**

```text
Intent:
  add patchplan resource registry

Touched:
  internal/patchplan/resources.go
  internal/patchplan/resources_test.go

Validation:
  go test ./...
  resource traversal tests
```

Review projection is the human-facing view of the patch contract.

---

# 19. Evidence ledger

| Field                  | Description                                                                                                |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Use case**           | “Why do we trust this patch?”                                                                              |
| **Conceptual problem** | A commit hash alone does not prove the patch satisfied its contract.                                       |
| **Solution**           | Record validation commands, outputs, artifact hashes, staged diff hash, commit hash, and policy decisions. |
| **Typical tools**      | JSON report, CUE evidence schema, CI logs, Git notes.                                                      |
| **Relates to**         | Validation, context replay, audit.                                                                         |

**Pattern**

```text
patch unit
→ staged diff hash
→ validators
→ results
→ commit hash
→ evidence record
```

**Example**

```json
{
  "patch": "contracts/resources",
  "staged_diff_hash": "sha256:...",
  "validators": ["go test ./...", "cue vet ./..."],
  "result": "pass",
  "commit": "abc123"
}
```

Evidence connects patch intent to validated history.

---

# 20. Rollback and recovery

| Field                  | Description                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “How do we recover from failed staging, validation, commit, or replay?”                                       |
| **Conceptual problem** | VCS operations mutate state. Recovery must preserve user work while restoring control invariants.             |
| **Solution**           | Define rollback per phase: index restore, worktree restore, commit reset, branch restore, stash/export patch. |
| **Typical tools**      | Git reset, reflog, stash, worktree, patch files, transaction logs.                                            |
| **Relates to**         | Staging transaction, validation gates, stack replay.                                                          |

**Pattern**

```text
phase failure
→ identify mutation scope
→ restore prior state
→ preserve user edits
→ report recovery state
```

**Rollback classes**

| Class      | Scope                                |
| ---------- | ------------------------------------ |
| `index`    | restore staged state only            |
| `worktree` | restore files from snapshot or patch |
| `commit`   | reset/revert committed change        |
| `branch`   | restore ref from reflog              |
| `artifact` | remove/regenerate transient outputs  |

Rollback semantics must be explicit before mutation.

---

# 21. Remote synchronization

| Field                  | Description                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Use case**           | “When can the stack be pushed or shared?”                                                   |
| **Conceptual problem** | A local stack may be valid locally but diverged from upstream or blocked by policy.         |
| **Solution**           | Check upstream, fetch state, branch divergence, CI policy, and push permission before sync. |
| **Typical tools**      | Git fetch, status -sb, remote refs, forge API, CI.                                          |
| **Relates to**         | Rebase, validation, review projection.                                                      |

**Pattern**

```text
validated local stack
→ upstream check
→ rebase/revalidate if needed
→ push / block
```

Remote sync is downstream of local validation.

---

# 22. MCP VCS adapter

| Field                  | Description                                                                     |
| ---------------------- | ------------------------------------------------------------------------------- |
| **Use case**           | “Expose patch stack operations to agents safely.”                               |
| **Conceptual problem** | Agents need VCS capabilities without raw shell access or uncontrolled mutation. |
| **Solution**           | Expose bounded MCP tools and resources backed by typed VCS contracts.           |
| **Typical tools**      | MCP, Go adapter, Git CLI/go-git, CUE contracts.                                 |
| **Relates to**         | Patch unit contract, staging transaction, validation, evidence.                 |

**Pattern**

```text
agent request
→ MCP tool schema
→ VCS adapter
→ bounded Git operation
→ normalized result
```

**Example MCP resources**

```text
vcs://repo/status
vcs://repo/head
vcs://diff/working-tree
vcs://diff/staged
vcs://stack/current
vcs://evidence/latest
```

**Example MCP tools**

```text
vcs.status
vcs.diff
vcs.stack.plan
vcs.stack.stage
vcs.stack.validate
vcs.stack.finalizePatch
```

The MCP adapter is a projection, not the source of VCS truth.

---

# 23. Policy-gated mutation

| Field                  | Description                                                                       |
| ---------------------- | --------------------------------------------------------------------------------- |
| **Use case**           | “Which VCS actions may the agent perform?”                                        |
| **Conceptual problem** | Staging, committing, rebasing, resetting, and pushing have different risk levels. |
| **Solution**           | Require explicit policy per operation class and workflow phase.                   |
| **Typical tools**      | CUE policy, MCP tool metadata, approval gates, risk classifier.                   |
| **Relates to**         | MCP adapter, rollback, evidence.                                                  |

**Pattern**

```text
requested VCS operation
→ risk class
→ policy decision
→ allow / deny / require approval
```

**Risk classes**

| Operation            | Risk                            |
| -------------------- | ------------------------------- |
| status/diff/log      | read                            |
| stage selected hunks | controlled write                |
| commit staged patch  | history write                   |
| reset/rebase         | destructive/local-history write |
| push                 | remote write                    |

Policy gates make the patch stack agent-safe.

---

# Relationship map

```text
repo root
  ↓
VCS snapshot
  ↓
dirty-state classification
  ↓
diff parsing
  ↓
semantic segmentation
  ↓
patch unit contracts
  ↓
dependency ordering
  ↓
stack plan
  ↓
staging transaction ─────→ index rollback
  ↓
validation gate ─────────→ candidate rejection semantics
  ↓
commit finalization
  ↓
evidence ledger
  ↓
stack progression
  ↓
review / push / replay
```

---

# Layered maturity model

## Level 0 — Manual Git

```text
git status
git add
git commit
```

| Strength  | Weakness                        |
| --------- | ------------------------------- |
| Universal | Easy to stage unrelated changes |

Use for tiny changes.

---

## Level 1 — File-level patching

```text
git add path
git diff --name-status
```

| Strength                    | Weakness                    |
| --------------------------- | --------------------------- |
| Simple segmentation by file | Cannot separate mixed hunks |

Use for clean file-scoped changes.

---

## Level 2 — Hunk-aware staging

```text
git add -p
git apply --cached
```

| Strength              | Weakness                                 |
| --------------------- | ---------------------------------------- |
| Can split mixed files | Still mostly manual and weakly validated |

Use for partial commits.

---

## Level 3 — Contracted patch units

```text
patch contract + staged diff validation
```

| Strength                 | Weakness                    |
| ------------------------ | --------------------------- |
| Patch intent is explicit | Requires schema and tooling |

Use for agent-assisted commits.

---

## Level 4 — Transactional stack

```text
stage → validate → finalize → evidence → rollback
```

| Strength                  | Weakness                                    |
| ------------------------- | ------------------------------------------- |
| Safe, replayable workflow | Requires state snapshots and rollback logic |

Use for multi-slice implementation.

---

## Level 5 — Agent-operable VCS control plane

```text
MCP VCS resources/tools + CUE policy + evidence ledger
```

| Strength                  | Weakness                                    |
| ------------------------- | ------------------------------------------- |
| Agents can operate safely | Needs strict contracts and permission gates |

Use for controlled automation.

---

# Practical pattern stack for contract.cuemod

Given the project direction, the strong stack is:

```text
CUE patch contract
→ Git state adapter
→ diff/hunk parser
→ patch unit planner
→ transactional staging
→ validation gate
→ finalizePatch
→ evidence ledger
→ MCP VCS resources/tools
```

## Minimal viable toolchain

| Layer              | Tool                                    |
| ------------------ | --------------------------------------- |
| VCS backend        | Git CLI or go-git                       |
| Contract authority | CUE                                     |
| Diff parsing       | Git patch output / parser               |
| Staging            | Git index operations                    |
| Validation         | `go test`, `cue vet`, project checks    |
| Evidence           | JSON report, Git hash, validator output |
| Agent bridge       | MCP Go adapter                          |

---

# Hard invariants

```text
No commit without staged-diff validation.
No staging outside patch unit contract.
No mutation without pre-mutation snapshot.
No rollback that discards user work unless explicitly requested.
No candidate rejection encoded as adapter failure.
No direct shell escape from agent tool input.
No push/rebase/reset in the initial safe slice.
```

---

# Best pattern names to keep

| Pattern                       | Core question                                 |
| ----------------------------- | --------------------------------------------- |
| Repository state snapshot     | What state are we starting from?              |
| Dirty-state classification    | What kind of changes exist?                   |
| Diff parsing                  | What exactly changed?                         |
| Semantic patch segmentation   | Which changes belong together?                |
| Patch unit contract           | What must this patch contain and prove?       |
| Patch dependency ordering     | What must come first?                         |
| Staging transaction           | Can we stage exactly this unit?               |
| Index rollback                | Can we recover failed staging?                |
| Worktree safety guard         | Did anything mutate outside scope?            |
| Generated artifact handling   | Should outputs be committed or evidence-only? |
| Validation gate               | Does the patch satisfy its contract?          |
| Candidate rejection semantics | Rejected patch or failed adapter?             |
| Commit finalization           | Can this become a commit?                     |
| Commit message synthesis      | What should the commit say?                   |
| Stack progression             | What is next?                                 |
| Conflict detection            | Will this patch conflict?                     |
| Rebase / replay               | Can the stack move bases?                     |
| Review projection             | How should this be reviewed?                  |
| Evidence ledger               | Why do we trust it?                           |
| Rollback and recovery         | How do we recover safely?                     |
| Remote synchronization        | Can this leave the machine?                   |
| MCP VCS adapter               | How does an agent use this safely?            |
| Policy-gated mutation         | Is this operation allowed?                    |
