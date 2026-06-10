# contract.cuemod regenerated slice

This archive replaces Python JSON validation with CUE workflow commands and adds a contract-first lint toolchain model.

## Files

- `workspace.cue` — root constants and generated projection paths
- `workspace.schema.cue` — contract types and constraints
- `workspace.hosts.cue` — host workspace declarations
- `workspace.projects.cue` — project sessions and lint toolchain policies
- `workspace.domains.cue` — domain routing and ownership
- `workspace.workflow.cue` — zero-drift terminal workspace policy
- `workspace.projections.cue` — generated projection values
- `workspace_tool.cue` — `cue cmd export`, `validate`, and `check`
- `dotfiles.schema-map.json` — evidence-backed map of the live dotfiles implementation
- `dotfiles.schema-map.cue` — validating shape derived from the initial map
- `justfile` — thin wrapper around CUE commands
- `docs/linting-toolchains.md` — linting architecture notes

## Command boundary

```text
CUE owns contract shape.
just exposes recipes.
shell-wrap executes declared adapters.
WezTerm hosts output.
```

## Validation

```bash
cue fmt .
cue cmd export
cue cmd validate
cue cmd check
cue vet dotfiles.schema-map.cue dotfiles.schema-map.json -d '#SchemaMap'
```

`cue` was not available in the generation environment, so run those commands locally before committing.
