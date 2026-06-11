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
cue vet ./providers/cue-lsp
cue vet ./providers/cue-rg
cue vet ./providers/lua-lsp
cue vet ./providers/chezmoi
cue vet ./adapters/git-mcp-go
cue vet ./projections/stage3
cue vet ./fixtures/mcp/valid
cue vet ./fixtures/resolver/workspace-lifecycle
cue vet ./migration

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

printf '%s\n' "contract checks: ok"
