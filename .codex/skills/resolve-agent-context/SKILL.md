---
name: resolve-agent-context
description: Resolve authoritative CUE task context before inspecting or editing dotfiles capabilities when a hook routing hint names this skill or the resolve-agent-context command.
---

# Agent Context Resolution

The hook hint is not task context. It contains candidate capability IDs only.

Before repository inspection or editing, call the CUE MCP resolver:

```text
cue.resolve_agent_context({
  "prompt": "<current user prompt>",
  "cwd": "<current working directory>",
  "candidates": ["<candidate capability from the hook hint>"]
})
```

Use the returned CUE projection as the task map and retain its `projection_id`.

- Resolve first; inspect second.
- For implementation evidence, select graph artifact IDs from the projection and call `cue.search_implementation` with `projection_id` and `artifact_ids`; do not invoke `rg` directly.
- Cite returned evidence IDs with exact paths and lines.
- Treat hook candidates as hints, never authority.
- Do not invoke `cue cmd` directly or hand-write temporary CUE input.
- Use `/home/_404/src/contract.cuemod/bin/resolve-agent-context` only as an explicitly reported Stage 2 fallback when the CUE MCP server is unavailable.
- Do not infer source/generated boundaries from the hook.
- Do not edit generated `.codex/hooks.json` or `.codex/skills/*`; regenerate them from `contract.cuemod`.
- Run validation commands only when `validation.required` is `true`.
