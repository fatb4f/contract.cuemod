#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)

cd "$repo_root"

cue export ./contracts/agent-context-resolver/assertions \
	-e agentContextResolverAssertions.agentContextHook \
	>/dev/null
