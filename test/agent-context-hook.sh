#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
hook="$repo_root/bin/dotfiles-agent-context-hook"
generated_hooks=/home/_404/src/dotfiles/.codex/hooks.json

run_hook() {
	prompt=$1
	printf '%s\n' \
		"{\"hook_event_name\":\"UserPromptSubmit\",\"prompt\":$(printf '%s' "$prompt" | jq -Rs .)}" |
		"$hook"
}

desktop=$(run_hook "Fix Hyprland brightness and session OSD")
printf '%s\n' "$desktop" | jq -e '
	.hookSpecificOutput.hookEventName == "UserPromptSubmit" and
	(.hookSpecificOutput.additionalContext | startswith("Dotfiles capability context:\n"))
' >/dev/null

desktop_context=$(printf '%s\n' "$desktop" | jq -r '.hookSpecificOutput.additionalContext | sub("^Dotfiles capability context:\\n"; "") | fromjson')
printf '%s\n' "$desktop_context" | jq -e '
	.capability.id == "desktop-session-lifecycle" and
	([.domains[].id] | index("chezmoi") != null) and
	([.domains[].id] | index("shell-wrap") != null) and
	([.repository.instructionBoundaries[].path] | index("shell-wrap/AGENTS.md") != null) and
	([.requiredWorkflows[].id] | index("session-bashly") != null) and
	([.requiredWorkflows[].id] | index("chezmoi-closeout") != null) and
	([.artifacts[] | select(.id == "session-generated-executable" and .editable == false)] | length == 1)
' >/dev/null

workspace=$(run_hook "Change the WezTerm workspace sessionizer")
workspace_context=$(printf '%s\n' "$workspace" | jq -r '.hookSpecificOutput.additionalContext | sub("^Dotfiles capability context:\\n"; "") | fromjson')
printf '%s\n' "$workspace_context" | jq -e '
	.capability.id == "workspace-lifecycle" and
	([.components[].id] | index("wezterm-sessionizer") != null) and
	(.repository.instructionBoundaries | length == 0)
' >/dev/null

run_hook "Update README wording" | jq -e '. == {}' >/dev/null
run_hook "Change Hyprland and the WezTerm workspace" | jq -e '. == {}' >/dev/null

generated=$(mktemp "${TMPDIR:-/tmp}/dotfiles-hooks.XXXXXX.json")
generated_sorted=$(mktemp "${TMPDIR:-/tmp}/dotfiles-hooks-generated.XXXXXX.json")
installed_sorted=$(mktemp "${TMPDIR:-/tmp}/dotfiles-hooks-installed.XXXXXX.json")
trap 'rm -f "$generated" "$generated_sorted" "$installed_sorted"' EXIT HUP INT TERM
(
	cd "$repo_root"
	cue export . dotfiles.schema-map.json -e codexHooks --out json >"$generated"
)
jq -S . "$generated" >"$generated_sorted"
jq -S . "$generated_hooks" >"$installed_sorted"
cmp "$generated_sorted" "$installed_sorted"

printf 'agent-context-hook: ok\n'
