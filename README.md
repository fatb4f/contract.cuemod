# contract.reflective-transition-factory

This repository is the reflective transition factory contract surface. The
factory admits changes only through bounded contract objects, fixture packets,
generated projections, worker aperture adapters, or explicitly quarantined
migration evidence.

## Authority surface

`contracts/factory/` is the active factory authority root.

- `contracts/factory/kernel/` and `contracts/factory/object/` define the contract objects.
- `contracts/factory/extraction/` seals the extraction surface for the
  dedicated factory repository migration.
- `contracts/factory/fixtures/` contains factory fixture and packet evidence.
- `contracts/factory/generated/` is reserved for factory generated artifacts.
- `contracts/factory/workers/` defines worker aperture references.
- `contracts/factory/adapters/` contains only factory aperture boundaries.
- `contracts/factory/assertions/` gates the pruning surface.
- `migration/legacy/` preserves old repo, VCS, provider, projection, fixture,
  generated, adapter, and documentation material as non-authority evidence.

Top-level fixtures and generated outputs are not source authority. They must be
factory fixtures, factory projections, or migration evidence.

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
