set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

check:
  test ! -e contracts/factory
  test ! -e fixtures
  test ! -e generated
  test ! -e providers
  test ! -e projections
  test ! -e adapters
  test ! -e test
  test ! -e contracts/repo
  test ! -e contracts/vcs

smoke:
  go test ./...
  just check
  printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | go run ./cmd/contract-mcp | rg 'acr\.(inventory|resolve_prompt|plan_route|validate|export_runtime_projection)' >/dev/null

fmt:
  cue fmt ./contracts/... ./migration/legacy/...

archive:
  tar --exclude=.git -czf ../contract.cuemod.tar.gz -C .. contract.cuemod
