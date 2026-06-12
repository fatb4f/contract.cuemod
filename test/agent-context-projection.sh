#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
generated="$repo_root/generated/agent_context_projection.json"
tmp_projection=$(mktemp "${TMPDIR:-/tmp}/agent-context-projection.XXXXXX.json")
trap 'rm -f "$tmp_projection"' EXIT HUP INT TERM

(
	cd "$repo_root"
	cue export ./projections/agent-context -e agentContextProjection >"$tmp_projection"
)

cmp "$tmp_projection" "$generated"

jq -e '
	.schema == "agent.context-fragment-projection.v1" and
	([.fragments[].id] | index("registry.agent-capability-routes") != null) and
	([.fragments[].id] | index("hook.user-prompt-routing-hint") != null)
' "$generated" >/dev/null

printf '%s\n' "agent-context-projection: ok"
