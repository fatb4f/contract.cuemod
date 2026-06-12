#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
hook="$repo_root/.codex/skills/resolve-agent-context/scripts/agent-context-resolver-hook"
resolver="$repo_root/.codex/skills/resolve-agent-context/scripts/resolve-agent-context"
generated_hooks="$repo_root/.codex/hooks.json"
generated_skill="$repo_root/.codex/skills/resolve-agent-context/SKILL.md"
generated_dir="$repo_root/generated/agent-context-resolver"

run_hook() {
	prompt=$1
	printf '%s\n' \
		"{\"hook_event_name\":\"UserPromptSubmit\",\"prompt\":$(printf '%s' "$prompt" | jq -Rs .)}" |
		"$hook"
}

hint=$(run_hook "Update the resolver hook without allowing MCP tool output to become context.")
hint_context=$(printf '%s\n' "$hint" | jq -r '.hookSpecificOutput.additionalContext | sub("^Agent context routing hint:\\n"; "") | fromjson')
printf '%s\n' "$hint_context" | jq -e '
	.schema == "agent.context-resolver.hint.v1" and
	(.availableFragmentIDs | index("agent-context-resolver.authority") != null) and
	(.availableFragmentIDs | index("agent-skill.projection") != null) and
	(.availableFragmentIDs | index("mcp.evidence-plane") != null) and
	(.selectedFragments | index("agent-context-resolver.authority") != null) and
	(.selectedFragments | index("agent-skill.projection") != null) and
	(.selectedFragments | index("mcp.evidence-plane") != null) and
	([.selectedFragments[] as $id | .availableFragmentIDs | index($id) != null] | all) and
	.generatedFrom.turnStart == "generated/agent-context-resolver/turn_start_fragments.json" and
	.generatedFrom.routes == "generated/agent-context-resolver/prompt_routes.json"
' >/dev/null

resolved=$("$resolver" --prompt "Update the resolver hook without allowing MCP tool output to become context.")
printf '%s\n' "$resolved" | jq -e '
	.schema == "agent.context-resolver.hint.v1" and
	([.selectedFragments[] as $id | .availableFragmentIDs | index($id) != null] | all)
' >/dev/null

run_hook "Update README wording" | jq -e '. == {}' >/dev/null

tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/agent-context-resolver.XXXXXX")
trap 'rm -rf "$tmp_root"' EXIT HUP INT TERM
mkdir -p "$tmp_root/generated"
(
	cd "$repo_root"
	cue export ./contracts/registry.cue -e repoRegistry --force --out json --outfile "$tmp_root/generated/registry.index.json"
	go run ./seeds/contract-cuemod/agent-context-resolver/cmd/seed-resolver/main.go generate \
		--registry "$tmp_root/generated/registry.index.json" \
		--out "$tmp_root/generated"
	cue export ./projections/agent-skill -e projection.hooks --out json >"$tmp_root/hooks.json"
	cue export ./projections/agent-skill -e skillContent --out text >"$tmp_root/SKILL.md"
	cue export ./projections/agent-skill -e 'projection.scripts["agent-context-resolver-hook"].content' --out text >"$tmp_root/agent-context-resolver-hook"
	cue export ./projections/agent-skill -e 'projection.scripts["resolve-agent-context"].content' --out text >"$tmp_root/resolve-agent-context"
)

diff -ru "$generated_dir" "$tmp_root/generated"
jq -S . "$tmp_root/hooks.json" >"$tmp_root/hooks.generated.sorted"
jq -S . "$generated_hooks" >"$tmp_root/hooks.installed.sorted"
cmp "$tmp_root/hooks.generated.sorted" "$tmp_root/hooks.installed.sorted"
cmp "$tmp_root/SKILL.md" "$generated_skill"
cmp "$tmp_root/agent-context-resolver-hook" "$hook"
cmp "$tmp_root/resolve-agent-context" "$resolver"

jq -r '
	.contracts[]
	| .authorityRoot, .contractPath, (.fragments[].sourcePath)
' "$generated_dir/registry.index.json" |
	while IFS= read -r path; do
		[ -e "$repo_root/$path" ] || {
			printf 'registry references missing authority path: %s\n' "$path" >&2
			exit 1
		}
	done

[ -x "$hook" ]
[ -x "$resolver" ]
[ ! -e "$repo_root/.codex/skills/resolve-agent-context/scripts/dotfiles-agent-context-hook" ]

if grep -R "dotfiles-agent-context-hook" "$repo_root/.codex"; then
	printf '%s\n' "generated agent assets reference the stale dotfiles hook" >&2
	exit 1
fi

printf 'agent-context-hook: ok\n'
