# contract.cuemod

This repository is the typed authority graph for MCP-mediated semantic access.
Raw files are storage, MCP providers are access paths, and CUE contracts define
which provider may expose facts about an artifact.

## Authority surface

`contracts/` is the only contract authority root.

- `contracts/` defines MCP envelopes, graph identities, provider planes, and validation profiles.
- `adapters/` contains contract-managed snapshots of privileged backend implementations.
- `providers/` declares concrete `cue-lsp` and `lua-lsp` capabilities plus a deferred `chezmoi` identity.
- `projections/` exposes bounded views of the authority surface.
- `fixtures/` contains canonical provider result evidence.
- `fixtures/resolver/` contains typed forward, reverse, exclusion, and completeness packets.
- `migration/` quarantines observations that are not authority.
- `test/` vets the supported surface and rejects invalid direct-access and negative-claim cases.

The repository is intentionally not a source index. `raw_path` exists only as
provider execution metadata and every artifact access contract fixes
`access.direct` to `false`.

## Agent context delivery

The agent-context projection has three distinct boundaries:

- Stable registry context is materialized as compact generated `turn_start`
  fragments on the native `message`/`message` context surface.
- `UserPromptSubmit` selects declared fragment IDs and compact hints; it does
  not emit the full registry.
- MCP resources and tool results remain non-native result surfaces and do not
  imply model context.

The generated fragment inventory and Stage 3 proof report are deterministic
projections of `projections/agent-context`.

Stage 4 adds a deterministic prompt classifier over that stable inventory.
The generated classifier registry may select only fragment IDs already emitted
by the Stage 3 turn-start projection. Prompt-derived output contains the prompt,
selected IDs, compact hints, and rule evidence only; unknown, ambiguous, and
empty prompts safely select no fragments. Memories and heuristic text remain
non-authoritative, and MCP/tool routing receives no unvalidated prompt data.

Stage 5 adds a deterministic Codex lifecycle harness. It loads generated
turn-start fragment IDs before invoking the prompt classifier, validates every
selected ID against that native inventory, expands selected fragment metadata
inside the runtime, and exposes only that scoped expansion to a subagent.
Classifier callbacks receive IDs only and cannot assemble context bodies.

Stage 6 adds an opt-in live runtime adapter. A Codex SDK/runtime probe receives
a versioned request on stdin and emits four versioned JSONL lifecycle events:
turn-start availability, prompt classification, runtime expansion, and
subagent expansion. The adapter validates event order, declared IDs, canonical
fragment metadata, and subagent scoping before projecting the observation into
the same `agent.codex-lifecycle-report.v1` schema as the deterministic harness.
Normal CI does not require a live runtime or credentials.

Run the live comparison with a probe command configured as a JSON argv array:

```bash
CODEX_CONTEXT_LIVE_COMMAND_JSON='["/path/to/codex-runtime-probe"]' \
  go test ./internal/codexcontext -tags=integration
```

The probe request schema is `agent.codex-lifecycle-request.v1`; emitted event
records use `agent.codex-lifecycle-event.v1`. The integration test compares the
validated live report to the deterministic report for the same prompt.
The probe must emit exactly these events in order:

```text
turn_start.fragments_available
user_prompt_submit.classified
runtime.selected_fragments_expanded
subagent.scoped_context_expanded
```

The first two events carry `fragmentIDs`; the final two carry canonical
fragment metadata in `context`. See
`internal/codexcontext/testdata/live_events.jsonl` for the wire format.

The managed `git-mcp-go` adapter is pinned to the `fatb4f/git-mcp-go`
`worktree-v0` branch. Its source is materialized without nested `.git`
metadata and remains an internal backend rather than a default agent surface.
The adapter's `pkg/transaction` package provides the guarded stack mutation
runner, durable journal, rollback dispatch, and transaction evidence runtime.

## Validation

```bash
just check
```
