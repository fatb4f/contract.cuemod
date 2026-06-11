#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
hook="$repo_root/bin/dotfiles-agent-context-hook"
resolver="$repo_root/bin/resolve-agent-context"
generated_hooks=/home/_404/src/dotfiles/.codex/hooks.json
generated_skill=/home/_404/src/dotfiles/.codex/skills/resolve-agent-context/SKILL.md

run_hook() {
	prompt=$1
	printf '%s\n' \
		"{\"hook_event_name\":\"UserPromptSubmit\",\"prompt\":$(printf '%s' "$prompt" | jq -Rs .)}" |
		"$hook"
}

hint=$(run_hook "How are environment variables injected when switching WezTerm sessions?")
hint_context=$(printf '%s\n' "$hint" | jq -r '.hookSpecificOutput.additionalContext | sub("^Agent context routing hint:\\n"; "") | fromjson')
printf '%s\n' "$hint_context" | jq -e '
	.schema == "agent.hook-hint.v1" and
	.candidates == ["workspace-lifecycle"] and
	.matchedTerms == ["wezterm"] and
	.resolver.tool == "cue.resolve_agent_context" and
	(.resolver.fallbackCommand | endswith("/resolve-agent-context")) and
	.resolver.skill == ".codex/skills/resolve-agent-context/SKILL.md" and
	(has("components") | not) and
	(has("validation") | not)
' >/dev/null

hint_size=$(printf '%s\n' "$hint_context" | jq -c . | wc -c)
[ "$hint_size" -lt 1024 ]

read_only=$(
	"$resolver" \
		--prompt "How are environment variables injected when switching WezTerm sessions?" \
		--cwd /home/_404/src/dotfiles \
		--candidate workspace-lifecycle
)
printf '%s\n' "$read_only" | jq -e '
	.schema == "agent.context-projection.v1" and
	.decision.capability == "workspace-lifecycle" and
	.decision.mode == "read-only" and
	.validation.required == false and
	.validation.commands == [] and
	([.components[].id] | index("wezterm-sessionizer") != null)
' >/dev/null

implementation_read_only=$(
	"$resolver" \
		--prompt "Cite exact implementation evidence for the WezTerm sessionizer" \
		--cwd /home/_404/src/dotfiles \
		--candidate workspace-lifecycle
)
printf '%s\n' "$implementation_read_only" | jq -e '
	.decision.mode == "read-only" and
	.validation.required == false
' >/dev/null

candidate_is_hint=$(
	"$resolver" \
		--prompt "How does the WezTerm sessionizer switch workspaces?" \
		--cwd /home/_404/src/dotfiles \
		--candidate desktop-session-lifecycle
)
printf '%s\n' "$candidate_is_hint" | jq -e '
	.decision.capability == "workspace-lifecycle"
' >/dev/null

mutation=$(
	"$resolver" \
		--prompt "Fix Hyprland brightness through the session CLI" \
		--cwd /home/_404/src/dotfiles \
		--candidate desktop-session-lifecycle
)
printf '%s\n' "$mutation" | jq -e '
	.decision.capability == "desktop-session-lifecycle" and
	.decision.mode == "mutation" and
	.validation.required == true and
	(.validation.commands | length > 0) and
	([.boundaries.source[]] | index("shell-wrap/src/session/src") != null) and
	([.boundaries.generated[]] | index("shell-wrap/src/session/session") != null) and
	([.mutationPolicy.neverEditDirectly[]] | index("shell-wrap/src/session/session") != null)
' >/dev/null

run_hook "Update README wording" | jq -e '. == {}' >/dev/null
run_hook "Change Hyprland and the WezTerm workspace" | jq -e '. == {}' >/dev/null

tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/agent-context-projections.XXXXXX")
trap 'rm -rf "$tmp_root"' EXIT HUP INT TERM
(
	cd "$repo_root"
	cue export . dotfiles.schema-map.json -e codexHooks --out json >"$tmp_root/hooks.json"
	cue export . dotfiles.schema-map.json -e codexSkill --out text >"$tmp_root/SKILL.md"
)
jq -S . "$tmp_root/hooks.json" >"$tmp_root/hooks.generated.sorted"
jq -S . "$generated_hooks" >"$tmp_root/hooks.installed.sorted"
cmp "$tmp_root/hooks.generated.sorted" "$tmp_root/hooks.installed.sorted"
cmp "$tmp_root/SKILL.md" "$generated_skill"

printf 'agent-context-hook: ok\n'
