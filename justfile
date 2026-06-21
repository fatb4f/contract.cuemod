set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

check:
  cd contracts/factory && cue vet -c=false . ./object ./transition ./workers ./workers/codex ./workers/cue ./workers/cue/cue-lsp ./workers/cue/cue-rg ./workers/gitbutler ./adapters ./assertions
  cd contracts/factory && cue eval ./assertions -c >/dev/null
  cd contracts/factory && cue vet ./fixtures/negative/valid
  cd contracts/factory && ! cue vet ./fixtures/negative/invalid-candidate-without-negative-fixture
  cd contracts/factory && ! cue vet ./fixtures/negative/invalid-candidate-raw-output
  cd contracts/factory && ! cue vet ./fixtures/negative/invalid-evaluation-without-fixture-verdict
  cd contracts/factory && ! cue vet ./fixtures/negative/invalid-feedback-admits-failed-evaluation
  cd contracts/factory && ! cue vet ./fixtures/negative/invalid-transition-without-admitted-feedback
  cd contracts/factory && ! cue vet ./fixtures/negative/invalid-materialization-before-admitted-transition
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
