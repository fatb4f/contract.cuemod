# workspace-contract

Adapter-neutral CUE contract for `/home/_404/src`.

This repo declares two global object families:

```text
hostWorkspaces
→ machine/control-plane implementation repos

projectSessions
→ launchable project contexts under /home/_404/src
```

Adapters consume projections; they do not own the domain objects.

```text
CUE contract
→ workspace.projects.json
→ WezTerm / xplr / just / editor / shell adapters
```

## Files

| File | Role |
|---|---|
| `workspace.schema.cue` | Core types and constraints |
| `workspace.hosts.cue` | Host workspace declarations |
| `workspace.projects.cue` | Project session declarations |
| `workspace.domains.cue` | Dotfiles domain routing registry |
| `workspace.workflow.cue` | Terminal workflow policy |
| `workspace.projections.cue` | Exported projection objects |
| `workspace_tool.cue` | Optional `cue cmd export` workflow |
| `workspace.projects.json` | Adapter-neutral project/session projection |
| `workspace.hosts.json` | Adapter-neutral host-workspace projection |
| `workspace.contract.json` | Combined projection |

## Generate projections

```bash
cue export . -e hostManifest --out json > workspace.hosts.json
cue export . -e projectManifest --out json > workspace.projects.json
cue export . -e domainManifest --out json > workspace.domains.json
cue export . -e workflowManifest --out json > workspace.workflow.json
cue export . -e contractManifest --out json > workspace.contract.json
```

Or, if CUE workflow commands are enabled:

```bash
cue cmd export
```

## Validate generated JSON

```bash
python3 scripts/validate_json.py
```

## Adapter rule

Adapters may read `workspace.projects.json` and select fields under `projects[].adapters.<adapter>`.

They must not:

```text
- discover project roots at runtime;
- mutate the contract;
- treat generated JSON as adapter-owned state;
- become the authority for workspace membership.
```

## WezTerm example

See `adapters/wezterm/workspaces.lua` for a consumer example that maps project contexts to WezTerm workspaces.
