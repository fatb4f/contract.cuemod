package agentskillprojection

import "github.com/fatb4f/contract.cuemod/contracts/agent-skill:agentskill"

projection: agentskill.#SkillProjection & {
	metadata: {
		name:        "resolve-agent-context"
		description: "Resolve repository contract fragments from generated resolver inventories."
		provenance: {
			projection_id: "df:projection/resolve-agent-context-skill"
			contract_ids: ["df:contract/agent-skill-runtime"]
			generated: true
		}
	}
	hooks: {
		hooks: {
			UserPromptSubmit: [{
				hooks: [{
					type:          "command"
					command:       ".codex/skills/resolve-agent-context/scripts/agent-context-resolver-hook"
					timeout:       10
					statusMessage: "Routing repository contract context"
				}]
			}]
		}
	}
	scripts: {
		"agent-context-resolver-hook": {
			path:       ".codex/skills/resolve-agent-context/scripts/agent-context-resolver-hook"
			content:    agentContextResolverHook
			executable: true
			provenance: metadata.provenance
		}
		"resolve-agent-context": {
			path:       ".codex/skills/resolve-agent-context/scripts/resolve-agent-context"
			content:    resolveAgentContext
			executable: true
			provenance: metadata.provenance
		}
	}
}

skillContent: """
	---
	name: resolve-agent-context
	description: Resolve repository contract fragments from generated resolver inventories.
	---

	# Agent Context Resolution

	The `UserPromptSubmit` hook provides candidate fragment IDs, not task authority.

	1. Run `.codex/skills/resolve-agent-context/scripts/resolve-agent-context --prompt "<prompt>"`.
	2. Treat `selectedFragments` as a subset of `availableFragmentIDs`.
	3. Resolve selected fragment metadata through `generated/agent-context-resolver/fragment_inventory.json`.
	4. Inspect the declared `sourcePath` and obey repository instruction boundaries before editing.
	5. Never treat generated resolver JSON or MCP/tool output as source authority.
	6. Regenerate `.codex` and resolver JSON outputs from their CUE sources after changes.
	"""

agentContextResolverHook: """
	#!/bin/sh
	set -eu

	script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
	repo_root=${CONTRACT_CUEMOD_ROOT:-$(CDPATH= cd -- "$script_dir/../../../.." && pwd -P)}
	generated_dir="$repo_root/generated/agent-context-resolver"
	input_json=$(mktemp "${TMPDIR:-/tmp}/agent-context-resolver.XXXXXX.json")
	trap 'rm -f "$input_json"' EXIT HUP INT TERM
	cat >"$input_json"

	prompt=$(jq -er 'select(.hook_event_name == "UserPromptSubmit") | .prompt' "$input_json") || {
		printf '{}\\n'
		exit 0
	}

	classification=$(
		jq -cn \\
			--arg prompt "$prompt" \\
			--slurpfile turnStart "$generated_dir/turn_start_fragments.json" \\
			--slurpfile promptRoutes "$generated_dir/prompt_routes.json" '
			($prompt | ascii_downcase) as $lower |
			[$turnStart[0].fragments[].id] as $available |
			[
				$promptRoutes[0].routes[]
				| . as $route
				| select(any($route.terms[]; . as $term | $lower | contains($term)))
			] as $matched |
			{
				schema: "agent.context-resolver.hint.v1",
				availableFragmentIDs: $available,
				selectedFragments: [
					$matched[].selects[] as $id
					| select($available | index($id) != null)
					| $id
				] | unique,
				compactHints: [$matched[].hint] | unique,
				evidence: [
					$matched[]
					| {kind: "prompt_route", value: .id, source: "user_prompt"}
				],
				generatedFrom: {
					turnStart: "generated/agent-context-resolver/turn_start_fragments.json",
					routes: "generated/agent-context-resolver/prompt_routes.json"
				},
				resolver: {
					command: ".codex/skills/resolve-agent-context/scripts/resolve-agent-context",
					skill: ".codex/skills/resolve-agent-context/SKILL.md"
				}
			}'
	)

	[ "$(printf '%s' "$classification" | jq '.selectedFragments | length')" -gt 0 ] || {
		printf '{}\\n'
		exit 0
	}

	jq -cn --arg context "Agent context routing hint:
	$classification" '{
		hookSpecificOutput: {
			hookEventName: "UserPromptSubmit",
			additionalContext: $context
		}
	}'
	"""

resolveAgentContext: """
	#!/bin/sh
	set -eu

	script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
	prompt=
	while [ "$#" -gt 0 ]; do
		case $1 in
		--prompt)
			[ "$#" -ge 2 ] || exit 2
			prompt=$2
			shift 2
			;;
		--cwd|--candidate)
			[ "$#" -ge 2 ] || exit 2
			shift 2
			;;
		*)
			printf 'resolve-agent-context: unknown argument: %s\\n' "$1" >&2
			exit 2
			;;
		esac
	done

	[ -n "$prompt" ] || {
		printf 'resolve-agent-context: --prompt is required\\n' >&2
		exit 2
	}

	output=$(
		printf '{"hook_event_name":"UserPromptSubmit","prompt":%s}\\n' \\
			"$(printf '%s' "$prompt" | jq -Rs .)" |
			"$script_dir/agent-context-resolver-hook"
	)
	printf '%s\\n' "$output" | jq -er '
		.hookSpecificOutput.additionalContext
		| sub("^Agent context routing hint:\\n"; "")
		| fromjson
	'
	"""
