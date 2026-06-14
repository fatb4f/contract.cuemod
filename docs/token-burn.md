
## Readout

The analyzer confirms two different burn patterns. The pasted report shows #32 had **385 log lines / 787 KB**, while #33 had **544 log lines / 852 KB**, with #33 doing more tool and patch iterations despite lower reported total tokens. 

## Pattern by run

| Run | Resume ID                              | Main burn pattern             | Evidence                                                                                                               |
| --- | -------------------------------------- | ----------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| #32 | `019ec3b7-a78a-7803-b61a-ed37f4476aef` | Broad architecture fanout     | `51 exec_command`, `11 apply_patch`, heavy `contracts/repo/*`, generated/projection/hook paths                         |
| #33 | `019ec402-0a53-73c2-bbe6-9cf39f505693` | Fixture/policy iteration loop | `72 exec_command`, `33 apply_patch`, `181` refs to `./fixtures/agent-runtime/registry.cue`, many invalid fixture paths |

## Main quota leaks

### 1. `apply_patch` loop exploded in #33

```text
#32 apply_patch: 11
#33 apply_patch: 33
```

That is the strongest signal. #33 was not expensive because of broad repo reads; it was expensive because it iterated through many fixture/policy patches.

**Control fix:**

```text
max apply_patch per micro-slice: 3
```

After 3 patches, stop and report blocker / next patch plan.

---

### 2. `exec_command` stayed too high

```text
#32 exec_command: 51
#33 exec_command: 72
combined: 123
```

That means Codex likely used shell validation, inspection, grep, diff, and test commands repeatedly.

**Control fix:**

```text
max exec_command per micro-slice: 12

Allowed:
  - rg/fd narrow target
  - cue vet narrow target
  - git diff
  - git status
  - optional final check
```

---

### 3. Full validation appears too often

`test/check.sh` appears **61 combined times** in the path counter.

That does not necessarily mean it ran 61 times, but it means the full validation script was repeatedly inspected, patched, diffed, or referenced.

**Control fix:**

```text
During micro-slice:
  cue vet ./contracts/agent-runtime
  cue vet ./fixtures/agent-runtime/<one-fixture>

Only final gate:
  ./test/check.sh
```

---

### 4. #33 fixture registry became the hot path

#33 top paths:

```text
./fixtures/agent-runtime/registry.cue: 181
github.com/fatb4f/contract.cuemod/fixtures/agent-runtime: 197
./contracts/agent-runtime/invocation.cue: 70
```

This confirms the earlier diagnosis: fixture scaffolding is the next compression target.

**Control fix:**

Add a fixture helper/factory slice before more negative cases:

```text
fixtures/agent-runtime/
  registry.cue
    #BaseInvocation
    #BaseResult
    #InvalidInvocationWith
```

Then future invalid fixtures become tiny overlays.

---

### 5. #32 pulled unrelated repo/VCS files

#32 hot paths include:

```text
./contracts/repo/asset.cue: 88
./contracts/repo/vcs_workflow_fixtures.cue: 84
```

For an `agent-runtime` slice, that is context bleed.

**Control fix:**

Prompt must explicitly deny:

```text
Do not inspect contracts/repo/*
Do not patch contracts/repo/*
Do not run repo/vcs validation unless narrow validation proves this dependency is required
```

---

### 6. GitHub issue workflow is non-trivial overhead

Combined GitHub/issue operations include:

```text
_add_issue_comment: 6
_update_issue: 4
_update_pull_request: 4
_issue_read/_issue_write: 6
github_mcp.*: several
```

**Control fix:**

Split implementation and issue hygiene:

```text
implementation run:
  no GitHub issue update
  no issue close

cheap follow-up:
  inspect commit
  comment/close issue
```

---

## Updated micro-slice guardrail

Use this as the next Codex prompt preamble:

```text
Mode: micro-slice / quota critical.

Hard caps:
- max 12 exec_command calls
- max 3 apply_patch calls
- max 1 contract invariant
- max 1 positive fixture
- max 1 negative fixture
- no GitHub issue update/close
- no generated projection updates
- no contracts/repo inspection
- no full fixture matrix
- final response max 20 lines

Allowed paths only:
- contracts/agent-runtime/<specific-file>.cue
- fixtures/agent-runtime/<specific-fixture>
- test/check.sh only if validation list must be updated

Validation:
- run narrow cue vet first
- run ./test/check.sh at most once, only before commit
- stop on first validation class failure and summarize blocker
```

## Add to contract model

```cue
#RunBudget: close({
  mode: "micro-slice"

  maxExecCommands: 12
  maxApplyPatches: 3
  maxContractFiles: 1
  maxPositiveFixtures: 1
  maxNegativeFixtures: 1

  deny: {
    githubIssueWorkflow: true
    generatedProjectionUpdates: true
    unrelatedRepoInspection: true
    fixtureMatrixExpansion: true
    longFinalReport: true
  }
})
```

## Bottom line

The next quota win is not more route architecture. It is **execution discipline**:

```text
#32 leak: broad surface fanout
#33 leak: fixture iteration fanout

next fix:
  hard command/patch caps
  fixture helper compression
  one-invariant micro-slices
  issue workflow split out
```
