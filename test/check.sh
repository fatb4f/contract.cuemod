#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
cd "$repo_root"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT HUP TERM
resolver_contract_dir="$repo_root/contracts/agent-context-resolver"

cue vet ./contracts/graph
cue vet ./contracts
cue vet ./contracts/adapters
cue vet ./contracts/protocols/mcp
cue vet ./contracts/protocols/a2a
cue vet ./contracts/providers
cue vet ./contracts/context/packet
cue vet ./contracts/validation
cue vet ./contracts/agent-skill
cue vet ./contracts/agent-runtime
cue eval ./contracts/... >/dev/null
for root_domain in \
	./contracts/protocols/mcp \
	./contracts/protocols/a2a \
	./contracts/context/packet \
	./contracts/adapters \
	./contracts/agent-runtime \
	./contracts/agent-context-resolver
do
	cue export "$root_domain" >/dev/null
done
if cue export ./contracts/registry.cue -e repoRegistry | rg 'agent-context-resolver/(projections|adapters)/' >/dev/null; then
	printf '%s\n' "component-local resolver bindings registered as root authorities" >&2
	exit 1
fi
go test ./...
go run ./cmd/contractctl acr validate >/dev/null
go run ./cmd/contractctl acr inventory >/dev/null
go run ./cmd/contractctl acr export --target runtime-projection >/dev/null
printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' |
	go run ./cmd/contract-mcp |
	rg 'acr\.(inventory|resolve_prompt|plan_route|validate|export_runtime_projection)' >/dev/null
cue vet ./contracts/agent-context-resolver/...
cue export ./contracts/agent-context-resolver >/dev/null
cue export ./contracts/agent-context-resolver -e agentContextResolver.checkManifest \
	--force --out json --outfile "$tmp_dir/agent-context-resolver.check-manifest.json"
cmp "$tmp_dir/agent-context-resolver.check-manifest.json" \
	contracts/agent-context-resolver/generated/checks/check_manifest.json
cue export ./contracts/agent-context-resolver -e agentContextResolver.validationCertificate \
	--force --out json --outfile "$tmp_dir/agent-context-resolver.validation-certificate.json"
cmp "$tmp_dir/agent-context-resolver.validation-certificate.json" \
	contracts/agent-context-resolver/generated/checks/validation_certificate.json
cue vet ./contracts/repo
cue export ./contracts/repo -e vbContract >/dev/null
cue vet ./contracts/vb-reference
cue export ./contracts/vb-reference -e referenceComponent >/dev/null
cue export ./contracts/vb-reference -e referenceVirtualBranch >/dev/null
cue export ./contracts/vb-reference -e registryContribution >/dev/null
cue export ./contracts/registry.cue -e repoRegistry >/dev/null
./test/vb-reference-workflow.sh
cue vet ./contracts/vcs
cue export ./contracts/vcs >/dev/null
cue vet ./providers/cue-lsp
cue vet ./providers/cue-rg
cue vet ./providers/lua-lsp
cue vet ./providers/chezmoi
cue vet ./adapters/git-mcp-go
cue vet ./contracts/agent-context-resolver/projections/agent-skill
cue vet ./projections/repo
cue export ./projections/repo -e manifest >/dev/null
cue export ./projections/repo -e inventory >/dev/null
cue vet ./fixtures/mcp/valid
cue vet ./fixtures/mcp/adapter-output
cue vet ./fixtures/agent-skill/valid
cue vet ./fixtures/vb-contract/valid
cue vet ./fixtures/vcs/valid
(
	cd "$resolver_contract_dir"
	./seed/scripts/validate.sh
)

(
	cd "$resolver_contract_dir"
	cue export ./assertions -e agentContextResolverAssertions.agentContextHook >/dev/null
)
cue export ./contracts/repo/assertions -e repoLayoutAssertions >/dev/null

if cue vet ./fixtures/mcp/invalid-negative >/dev/null 2>&1; then
	printf '%s\n' "invalid negative claim unexpectedly passed" >&2
	exit 1
fi

if cue vet ./fixtures/mcp/invalid-direct >/dev/null 2>&1; then
	printf '%s\n' "invalid direct artifact access unexpectedly passed" >&2
	exit 1
fi

if cue vet ./fixtures/mcp/invalid-adapter-output >/dev/null 2>&1; then
	printf '%s\n' "invalid MCP adapter output unexpectedly passed" >&2
	exit 1
fi

for invalid_fixture in \
	./fixtures/agent-skill/invalid \
	./fixtures/mcp/invalid-authority \
	./fixtures/mcp/invalid-capability \
	./fixtures/mcp/invalid-complete \
	./fixtures/mcp/invalid-provider-id
do
	if cue vet "$invalid_fixture" >/dev/null 2>&1; then
		printf '%s\n' "$invalid_fixture unexpectedly passed" >&2
		exit 1
	fi
done

if cue vet ./fixtures/vcs/invalid-unpushed >/dev/null 2>&1; then
	printf '%s\n' "unpushed mutation turn unexpectedly passed" >&2
	exit 1
fi

if cue vet ./fixtures/vcs/invalid-reflog-only >/dev/null 2>&1; then
	printf '%s\n' "reflog-only non-ref rollback unexpectedly passed" >&2
	exit 1
fi

if cue vet ./fixtures/vcs/invalid-missing-transaction-policy >/dev/null 2>&1; then
	printf '%s\n' "stack mutator without transaction policy unexpectedly passed" >&2
	exit 1
fi

printf '%s\n' "contract checks: ok"
