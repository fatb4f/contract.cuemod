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
- `dotfiles.jsonld.cue` — contract graph, typed implementation, and JSON-LD context authority
- `fixtures/*.jsonld` — contract-bound smart-splits, session selection, and project IDE lifecycle graphs
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
cue vet . -d '#JSONLDDocument' json: fixtures/smart-splits.jsonld
cue vet . -d '#JSONLDDocument' json: fixtures/sessionizer.jsonld
cue vet . -d '#JSONLDDocument' json: fixtures/project-ide-lifecycle.jsonld
```

The explicit `json:` qualifier is required because CUE does not infer JSON from
the `.jsonld` extension.

## JSON-LD contract graph

CUE owns graph shape, reference resolution, and completeness. JSON-LD carries
stable contract, node, interface, implementation, symbol, artifact, and
evidence identities.

Lua source, LuaLS, `wezterm-types`, and WezTerm runtime observations remain
evidence-producing substrates. `ImplementationObject` and `TypedSymbol` record
only the boundary facts needed to bind those observations to workflow
contracts; they do not duplicate the WezTerm type universe.

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
- `cue.list_semantic_providers`
- `cue.search_implementation`
- `cue.validate_projection`

CUE resolves graph artifact IDs to bounded search targets. The Go server
executes one shell-free `rg` invocation per explicitly selected artifact,
derives stable evidence IDs, and CUE-vets the provider-bound response.

Stage 3 providers have distinct authority boundaries:

- `cue-rg-mcp` transports bounded evidence observations.
- `cue-lsp-mcp` describes the LSP-backed CUE semantic surface.
- `lua-lsp-mcp` describes the LSP-backed Lua semantic surface and requires
  `wezterm-types`.

MCP may join explicitly identified provider results. It may not infer component
ownership or authorize negative claims from file matches. Search results carry
`provider_id`, `artifact_id`, and `evidence_id`; `symbol_id` is reserved for
LSP-backed semantic observations.
