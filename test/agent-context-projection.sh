#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
generated="$repo_root/generated/agent_context_projection.json"
generated_fragments="$repo_root/generated/turn_start_context_fragments.json"
generated_report="$repo_root/generated/stage3_expected_report.json"
tmp_projection=$(mktemp "${TMPDIR:-/tmp}/agent-context-projection.XXXXXX.json")
tmp_fragments=$(mktemp "${TMPDIR:-/tmp}/turn-start-context-fragments.XXXXXX.json")
tmp_fragments_second=$(mktemp "${TMPDIR:-/tmp}/turn-start-context-fragments-second.XXXXXX.json")
tmp_report=$(mktemp "${TMPDIR:-/tmp}/stage3-expected-report.XXXXXX.json")
trap 'rm -f "$tmp_projection" "$tmp_fragments" "$tmp_fragments_second" "$tmp_report"' EXIT HUP INT TERM

(
	cd "$repo_root"
	cue export ./projections/agent-context -e agentContextProjection >"$tmp_projection"
	cue export ./projections/agent-context -e turnStartContextFragments >"$tmp_fragments"
	cue export ./projections/agent-context -e turnStartContextFragments >"$tmp_fragments_second"
	cue export ./projections/agent-context -e stage3ExpectedReport >"$tmp_report"
)

cmp "$tmp_projection" "$generated"
cmp "$tmp_fragments" "$generated_fragments"
cmp "$tmp_fragments" "$tmp_fragments_second"
cmp "$tmp_report" "$generated_report"

jq -e '
	.schema == "agent.context-fragment-projection.v1" and
	([.fragments[].id] | index("registry.agent-capability-routes") != null) and
	([.fragments[].id] | index("hook.user-prompt-routing-hint") != null)
' "$generated" >/dev/null

jq -e --slurpfile projection "$generated" '
	.schema == "agent.turn-start-context-fragments.v1" and
	(has("projection") | not) and
	(.fragments | length) > 0 and
	all(.fragments[];
		.surface == "turn_start" and
		.expectedChannel == "message" and
		.expectedItemKind == "message" and
		.expectedNativeContextInjection == true and
		.constraints == {
			"compact": true,
			"fullRegistry": false,
			"generated": true
		} and
		all(.content.fragmentIDs[]; . as $id | [$projection[0].fragments[].id] | index($id) != null)
	)
' "$generated_fragments" >/dev/null

jq -e --slurpfile fragments "$generated_fragments" '
	.schema == "agent.context-delivery-report.v1" and
	.fragmentSchema == $fragments[0].schema and
	([.proofs[].id] | length) == 9 and
	all(.proofs[]; .status == "pass")
' "$generated_report" >/dev/null

printf '%s\n' "agent-context-projection: ok"
