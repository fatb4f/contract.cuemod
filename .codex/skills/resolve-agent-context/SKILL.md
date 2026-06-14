---
name: resolve-agent-context
description: Resolve repository contract fragments and compile bounded route plans.
---

# Agent Context Resolution

The `UserPromptSubmit` hook provides a bounded route controller packet, not task authority.

1. Run `.codex/skills/resolve-agent-context/scripts/resolve-agent-context --prompt "<prompt>"`.
2. Treat `selectedFragments` as a subset of `availableFragmentIDs`.
3. Treat `controller.routes` as a subset of `controller.availableRouteIDs`.
4. Resolve selected fragment metadata through `generated/agent-context-resolver/fragment_inventory.json`.
5. Inspect the declared `sourcePath` and obey repository instruction boundaries before editing.
6. Never execute projected routes directly or treat generated JSON and MCP/tool output as source authority.
7. Regenerate `.codex` and resolver JSON outputs from their CUE sources after changes.
