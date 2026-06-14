#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
cd "$repo_root"

cue vet ./contracts/graph
cue vet ./contracts
cue vet ./contracts/adapters
cue vet ./contracts/mcp
cue vet ./contracts/providers
cue vet ./contracts/resolver
cue vet ./contracts/validation
cue vet ./contracts/agent-skill
cue vet ./contracts/agent-context-resolver
cue vet ./contracts/agent-runtime
cue vet ./contracts/agent-runtime/adapters
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
cue vet ./projections/stage3
cue vet ./projections/agent-skill
cue vet ./projections/repo
cue export ./projections/repo -e manifest >/dev/null
cue export ./projections/repo -e inventory >/dev/null
cue vet ./fixtures/mcp/valid
cue vet ./fixtures/mcp/adapter-output
cue vet ./fixtures/agent-skill/valid
cue vet ./fixtures/vb-contract/valid
cue vet ./fixtures/resolver/agent-context-resolver
cue vet ./fixtures/agent-runtime
cue vet ./fixtures/vcs/valid
cue vet ./fixtures/resolver/workspace-lifecycle
cue vet ./migration
./seeds/contract-cuemod/agent-context-resolver/scripts/validate.sh

./test/agent-context-hook.sh
./test/repo-layout.sh

if find adapters/git-mcp-go/source -name .git -print -quit | grep -q .; then
	printf '%s\n' "managed git-mcp-go adapter contains nested Git metadata" >&2
	exit 1
fi

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
	./fixtures/mcp/invalid-provider-id \
	./fixtures/resolver/agent-context-resolver/invalid-unknown-fragment \
	./fixtures/resolver/agent-context-resolver/invalid-mcp-tool-output \
	./fixtures/resolver/agent-context-resolver/invalid-hook-context-body \
	./fixtures/resolver/agent-context-resolver/invalid-full-registry \
	./fixtures/resolver/agent-context-resolver/invalid-assertion-false \
	./fixtures/resolver/agent-context-resolver/invalid-unavailable-selection \
	./fixtures/resolver/agent-context-resolver/invalid-unknown-route \
	./fixtures/resolver/agent-context-resolver/invalid-route-fragment \
	./fixtures/resolver/agent-context-resolver/invalid-route-dependency \
	./fixtures/resolver/agent-context-resolver/invalid-route-propagation \
	./fixtures/resolver/agent-context-resolver/invalid-direct-sdk-spawn \
	./fixtures/resolver/agent-context-resolver/invalid-runtime-execution \
	./fixtures/resolver/agent-context-resolver/invalid-route-authority \
	./fixtures/agent-runtime/invalid-arbitrary-prompt \
	./fixtures/agent-runtime/invalid-raw-transcript \
	./fixtures/agent-runtime/invalid-raw-registry \
	./fixtures/agent-runtime/invalid-unregistered-route \
	./fixtures/agent-runtime/invalid-unregistered-worker \
	./fixtures/agent-runtime/invalid-missing-budget
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
