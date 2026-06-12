#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
generated_registry="$repo_root/generated/prompt_classifier_registry.json"
tmp_registry=$(mktemp "${TMPDIR:-/tmp}/prompt-classifier-registry.XXXXXX.json")
tmp_registry_second=$(mktemp "${TMPDIR:-/tmp}/prompt-classifier-registry-second.XXXXXX.json")
tmp_input=$(mktemp "${TMPDIR:-/tmp}/prompt-classifier-input.XXXXXX.json")
trap 'rm -f "$tmp_registry" "$tmp_registry_second" "$tmp_input"' EXIT HUP INT TERM

(
	cd "$repo_root"
	cue export ./projections/agent-context -e promptClassifierRegistry >"$tmp_registry"
	cue export ./projections/agent-context -e promptClassifierRegistry >"$tmp_registry_second"
)

cmp "$tmp_registry" "$generated_registry"
cmp "$tmp_registry" "$tmp_registry_second"

classify() {
	prompt=$1
	jq -n --arg prompt "$prompt" '{promptClassifierInput: {prompt: $prompt}}' >"$tmp_input"
	(
		cd "$repo_root"
		cue export ./projections/agent-context "$tmp_input" -e promptClassification
	)
}

classify "resolve agent context for this task" | jq -e '
	.status == "selected" and
	.selectedFragments == [
		"registry.agent-capability-routes",
		"skill.resolve-agent-context"
	] and
	.evidence.matchedRules == ["resolve-agent-context"]
' >/dev/null

classify "rewrite the release notes" | jq -e '
	.status == "unknown" and
	.selectedFragments == [] and
	.evidence.rejectedRules == ["no-rule-match"]
' >/dev/null

classify "inspect context resolver runtime tools" | jq -e '
	.status == "ambiguous" and
	.selectedFragments == [] and
	.evidence.matchedRules == ["resolve-agent-context", "agent-runtime"]
' >/dev/null

classify "" | jq -e '
	.status == "noop" and
	.selectedFragments == [] and
	.evidence.rejectedRules == ["empty-prompt"]
' >/dev/null

printf '%s\n' "prompt-classifier: ok"
