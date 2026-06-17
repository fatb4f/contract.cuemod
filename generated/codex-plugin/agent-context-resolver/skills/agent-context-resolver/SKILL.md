# Agent Context Resolver

Use this skill when a Codex workflow needs the portable agent-context-resolver contract authority.

The contracts remain the authority. The MCP server and CLI evaluate CUE and expose resolver inventory, prompt routing, route planning, validation, and runtime projection operations.

Primary commands:

- `contractctl acr inventory`
- `contractctl acr resolve-prompt --input input.json`
- `contractctl acr plan-route --input input.json`
- `contractctl acr validate`
- `contractctl acr export --target runtime-projection`
- `contractctl serve mcp`
