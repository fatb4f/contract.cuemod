#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
cd "$repo_root"

cue vet ./contracts/graph
cue vet ./contracts/mcp
cue vet ./contracts/providers
cue vet ./contracts/validation
cue vet ./providers/cue-lsp
cue vet ./providers/lua-lsp
cue vet ./providers/chezmoi
cue vet ./projections/stage3
cue vet ./fixtures/mcp/valid
cue vet ./migration

if cue vet ./fixtures/mcp/invalid-negative >/dev/null 2>&1; then
	printf '%s\n' "invalid negative claim unexpectedly passed" >&2
	exit 1
fi

if cue vet ./fixtures/mcp/invalid-direct >/dev/null 2>&1; then
	printf '%s\n' "invalid direct artifact access unexpectedly passed" >&2
	exit 1
fi

printf '%s\n' "contract checks: ok"
