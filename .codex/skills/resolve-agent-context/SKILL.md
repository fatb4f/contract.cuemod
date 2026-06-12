---
name: resolve-agent-context
description: Resolve repository contract fragments from generated resolver inventories.
---

# Agent Context Resolution

The `UserPromptSubmit` hook provides candidate fragment IDs, not task authority.

1. Run `.codex/skills/resolve-agent-context/scripts/resolve-agent-context --prompt "<prompt>"`.
2. Treat `selectedFragments` as a subset of `availableFragmentIDs`.
3. Resolve selected fragment metadata through `generated/agent-context-resolver/fragment_inventory.json`.
4. Inspect the declared `sourcePath` and obey repository instruction boundaries before editing.
5. Never treat generated resolver JSON or MCP/tool output as source authority.
6. Regenerate `.codex` and resolver JSON outputs from their CUE sources after changes.
