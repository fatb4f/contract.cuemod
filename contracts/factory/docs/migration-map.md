# Migration Map

| Legacy path | Disposition | Factory path |
| --- | --- | --- |
| `fixtures/agent-runtime` | migrate | `contracts/factory/fixtures/packets/runtime/` |
| `fixtures/resolver` | migrate | `contracts/factory/fixtures/packets/resolver/` |
| `fixtures/mcp` | quarantine | `migration/legacy/fixtures/mcp/` |
| `fixtures/vcs` | quarantine | `migration/legacy/fixtures/vcs/` |
| `fixtures/vb-contract` | quarantine | `migration/legacy/fixtures/vb-contract/` |
| `generated/codex-plugin` | quarantine | `migration/legacy/generated/codex-plugin/` |
| `providers/cue-lsp` | migrate | `contracts/factory/workers/cue/cue-lsp/` |
| `providers/cue-rg` | migrate | `contracts/factory/workers/cue/cue-rg/` |
| `providers/lua-lsp` | quarantine | `migration/legacy/providers/lua-lsp/` |
| `providers/chezmoi` | quarantine | `migration/legacy/providers/chezmoi/` |
| `projections/repo` | quarantine | `migration/legacy/projections/repo/` |
| `adapters/git-mcp-go` | quarantine | `migration/legacy/adapters/git-mcp-go/` |
| `contracts/repo` | quarantine | `migration/legacy/contracts/repo/` |
| `contracts/vcs` | quarantine | `migration/legacy/contracts/vcs/` |
| `contracts/providers` | quarantine | `migration/legacy/contracts/providers/` |
| `contracts/context` | quarantine | `migration/legacy/contracts/context/` |
| `contracts/validation` | quarantine | `migration/legacy/contracts/validation/` |
| `docs/*` | quarantine | `migration/legacy/docs/` |
| `test/agent-context-hook.sh` | quarantine | `migration/legacy/test/agent-context-hook.sh` |
| `test/repo-layout.sh` | replace | `contracts/factory/assertions/gate.cue` and `just check` |
