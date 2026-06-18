# Factory Pruning Surface

The factory pruning surface keeps root authority narrow:

- `contracts/factory/` is the factory contract authority.
- `contracts/agent-runtime/` remains only as an active runtime input.
- `contracts/agent-context-resolver/` remains only as an active resolver input.
- `cmd/`, `internal/`, and `go.mod` remain only while current Go adapters build from them.
- `migration/legacy/` is temporary, explicit non-authority evidence.

No top-level `fixtures/`, `generated/`, `providers/`, `projections/`,
`adapters/`, or `test/` roots are retained as independent authority surfaces.
