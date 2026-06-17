# contract.cuemod

This repository is the typed authority graph for MCP-mediated semantic access.
Raw files are storage, MCP providers are access paths, and CUE contracts define
which provider may expose facts about an artifact.

## Authority surface

`contracts/` is the only contract authority root.

- `contracts/` defines MCP envelopes, graph identities, provider planes, and validation profiles.
- `adapters/` contains declarative references to external backend implementations.
- `providers/` declares concrete `cue-lsp` and `lua-lsp` capabilities plus a deferred `chezmoi` identity.
- top-level output, projection, fixture, seed, and runtime roots may exist as
  install targets or materialized views, but they are not resolver source
  authority.

The repository is intentionally not a source index. `raw_path` exists only as
provider execution metadata and every artifact access contract fixes
`access.direct` to `false`.

The `git-mcp-go` adapter declaration pins the external
`fatb4f/git-mcp-go` `worktree-v0` source. Its implementation is not vendored
into this contract catalogue.

## Agent Context Resolver

`contracts/agent-context-resolver/` is the resolver-owned contract root. It is
a contract-local domain with its own CUE module boundary:

```text
contracts/agent-context-resolver/
  cue.mod/module.cue       local CUE module boundary
  domain.cue              domain assembly surface
  assertions/             assertion authority for derived fixtures and checks
  fixtures/               resolver-owned evidence inputs
  checks/                 resolver-owned validation checks
  generated/              resolver-owned snapshots and validation exports
  projections/            Codex skill and runtime materialization contracts
  seed/                   resolver-owned seed inputs, scripts, and tooling
```

Generated snapshots, validation exports, projections, fixtures, checks, and
seed/tooling for the resolver are owned under that root. Upstream
compatibility fixtures are evidence inputs for compatibility validation; they
do not replace the resolver contract root as source authority.

## Validation

```bash
just check
```

Resolver-local closeout surface:

```bash
cue vet ./contracts/agent-context-resolver
cue export ./contracts/agent-context-resolver -e agentContextResolver
cue export ./contracts/agent-context-resolver -e routeInventory
cue export ./contracts/agent-context-resolver -e routeInventoryValidation
cue export ./contracts/agent-context-resolver -e routeCompilerProof
cue export ./contracts/agent-context-resolver -e agentContextResolver.checkManifest
cue export ./contracts/agent-context-resolver -e agentContextResolver.validationCertificate
```
