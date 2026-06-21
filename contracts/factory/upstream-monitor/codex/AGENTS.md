# Codex Monitor

This subtree contains loops whose upstream evidence source is Codex-related.

## Scope

Codex loops may only inspect upstream sources that are explicitly declared by the nearest loop AGENTS.md and loop-local CUE input files.

## Authority

The local monitor contracts, surface catalogue, report contracts, issue contracts, and templates are authority.

Upstream Codex repositories, pull requests, commits, releases, and docs are evidence only.

## Required behavior

Agents must:

```text
- load contracts/factory/upstream-monitor/AGENTS.md before loop-local instructions
- preserve the incoming signal ID across zone handoffs
- treat loop-local input CUE as the source of scope
- treat loop-local output CUE and templates as the only artifact shapes
```

Agents must not:

```text
- inspect openai/codex unless the active loop has admitted acquisition
- infer monitoring targets from directory names
- update issues or reports unless the active loop has admitted output behavior
- mutate local contract authority from upstream evidence
```
