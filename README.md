# contract.reflective-transition-factory

This repository no longer owns reflective transition factory authority. The
factory authority was extracted to `fatb4f/factory` through migration umbrella
`#66`.

## Authority surface

`contracts/factory/` is intentionally absent here. Current factory authority,
future factory issues, and scheduled upstream-monitor output belong in
`fatb4f/factory`.

This repository retains only extraction provenance under
`migration/factory-extraction/` and historical non-authority evidence under
`migration/legacy/`.

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
