#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
contract_root="$repo_root/contracts/agent-context-resolver"

cd "$contract_root"

cue export ./assertions \
	-e agentContextResolverAssertions.agentContextHook \
	>/dev/null
