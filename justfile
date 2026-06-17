set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

check:
  cue vet ./contracts/assertions
  cue eval ./contracts/assertions -c >/dev/null
  cue vet ./contracts/agent-context-resolver/assertions
  cue eval ./contracts/agent-context-resolver/assertions -c >/dev/null
  cue vet ./contracts/agent-runtime
  cue vet ./contracts/adapters
  cue vet ./contracts/protocols/mcp
  cue vet ./contracts/protocols/a2a
  cue vet ./contracts/context/packet

smoke:
  go test ./...
  go run ./cmd/contractctl acr validate >/dev/null
  go run ./cmd/contractctl acr inventory >/dev/null
  printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | go run ./cmd/contract-mcp | rg 'acr\.(inventory|resolve_prompt|plan_route|validate|export_runtime_projection)' >/dev/null

fmt:
  cue fmt ./contracts/... ./providers/... ./projections/... ./fixtures/...

archive:
  tar --exclude=.git -czf ../contract.cuemod.tar.gz -C .. contract.cuemod
