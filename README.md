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
- `dotfiles.agent-context.cue` — routing hints, resolver semantics, and generated skill projection
- `bin/dotfiles-agent-context-hook` — transport-only `UserPromptSubmit` hook adapter
- `bin/resolve-agent-context` — stable transport adapter for CUE context resolution
- `cmd/cue-mcp` — Stage 3 stdio MCP server exposing CUE authority and bounded implementation search
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
cue vet . dotfiles.schema-map.json
```

## Agent context POC

The project-local hook and resolver skill are generated into the dotfiles repository:

```bash
mkdir -p /home/_404/src/dotfiles/.codex/skills/resolve-agent-context
cue export . dotfiles.schema-map.json -e codexHooks \
  --out json > /home/_404/src/dotfiles/.codex/hooks.json
cue export . dotfiles.schema-map.json -e codexSkill \
  --out text > /home/_404/src/dotfiles/.codex/skills/resolve-agent-context/SKILL.md
```

The hook emits only a compact routing hint. `resolve-agent-context` transports
the prompt, cwd, and candidate IDs into CUE; matching, mode selection, authority
constraints, and validation activation remain in `dotfiles.agent-context.cue`.

## Stage 3 CUE MCP

Build and register the server:

```bash
just cue-mcp-build
codex mcp add cue \
  --env CUE_CONTRACT_ROOT=/home/_404/src/contract.cuemod \
  -- /home/_404/.local/bin/cue-mcp
```

The public tools are:

- `cue.resolve_agent_context`
- `cue.lookup_projection`
- `cue.search_implementation`
- `cue.validate_projection`

CUE produces the search roots and complete `rg` argv. The Go server validates
the authority envelope, executes `rg` without a shell, ranks evidence, derives
stable evidence IDs, and CUE-vets the typed response before returning it.
