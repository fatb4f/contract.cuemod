#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
cd "$repo_root"

cue vet ./contracts/graph
cue vet ./contracts/adapters
cue vet ./contracts/mcp
cue vet ./contracts/providers
cue vet ./contracts/resolver
cue vet ./contracts/validation
cue vet ./contracts/agent-skill
cue vet ./contracts/agent-context
cue vet ./contracts/repo
cue vet ./contracts/vcs
cue export ./contracts/vcs >/dev/null
cue vet ./providers/cue-lsp
cue vet ./providers/cue-rg
cue vet ./providers/lua-lsp
cue vet ./providers/chezmoi
cue vet ./adapters/git-mcp-go
cue vet ./projections/stage3
cue vet ./projections/agent-skill
cue vet ./projections/agent-context
cue vet ./projections/repo
cue export ./projections/repo -e manifest >/dev/null
cue export ./projections/repo -e inventory >/dev/null
cue vet ./fixtures/mcp/valid
cue vet ./fixtures/mcp/adapter-output
cue vet ./fixtures/agent-skill/valid
cue vet ./fixtures/agent-context/valid
cue vet ./fixtures/agent-context/prompt-classifier/valid
cue vet ./fixtures/vcs/valid
cue vet ./fixtures/resolver/workspace-lifecycle
cue vet ./migration

./test/agent-context-hook.sh
./test/agent-context-projection.sh
./test/prompt-classifier.sh
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
	./fixtures/mcp/invalid-provider-id
do
	if cue vet "$invalid_fixture" >/dev/null 2>&1; then
		printf '%s\n' "$invalid_fixture unexpectedly passed" >&2
		exit 1
	fi
done

if cue vet ./fixtures/agent-context/invalid-undeclared >/dev/null 2>&1; then
	printf '%s\n' "undeclared prompt fragment unexpectedly passed" >&2
	exit 1
fi

if cue vet ./fixtures/agent-context/invalid-turn-start-undeclared >/dev/null 2>&1; then
	printf '%s\n' "undeclared turn-start fragment unexpectedly passed" >&2
	exit 1
fi

if cue vet ./fixtures/agent-context/invalid-turn-start-full-registry >/dev/null 2>&1; then
	printf '%s\n' "full-registry turn-start fragment unexpectedly passed" >&2
	exit 1
fi

if cue vet ./fixtures/agent-context/prompt-classifier/invalid-fragment >/dev/null 2>&1; then
	printf '%s\n' "invalid prompt classifier fragment unexpectedly passed" >&2
	exit 1
fi

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
