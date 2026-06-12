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

The managed `git-mcp-go` adapter is pinned to the `fatb4f/git-mcp-go`
`worktree-v0` branch. Its source is materialized without nested `.git`
metadata and remains an internal backend rather than a default agent surface.
The adapter's `pkg/transaction` package provides the guarded stack mutation
runner, durable journal, rollback dispatch, and transaction evidence runtime.

## Validation

```bash
just check
```
