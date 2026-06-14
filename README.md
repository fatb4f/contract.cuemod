# contract.cuemod

This repository is the typed authority graph for MCP-mediated semantic access.
Raw files are storage, MCP providers are access paths, and CUE contracts define
which provider may expose facts about an artifact.

## Authority surface

`contracts/` is the only contract authority root.

- `contracts/` defines MCP envelopes, graph identities, provider planes, and validation profiles.
- `adapters/` contains declarative references to external backend implementations.
- `providers/` declares concrete `cue-lsp` and `lua-lsp` capabilities plus a deferred `chezmoi` identity.
- `projections/` exposes bounded views of the authority surface.
- `fixtures/` contains canonical provider result evidence.
- `fixtures/resolver/` contains typed forward, reverse, exclusion, and completeness packets.
- `test/` vets the supported surface and rejects invalid direct-access and negative-claim cases.

The repository is intentionally not a source index. `raw_path` exists only as
provider execution metadata and every artifact access contract fixes
`access.direct` to `false`.

The `git-mcp-go` adapter declaration pins the external
`fatb4f/git-mcp-go` `worktree-v0` source. Its implementation is not vendored
into this contract catalogue.

## Validation

```bash
just check
```
