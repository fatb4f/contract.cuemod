package workspace

import (
	"encoding/json"
	agentskill "github.com/fatb4f/contract.cuemod/contracts/agent-skill:agentskill"
	"list"
	"strings"
)

repository:         #SchemaMap.repository
domains:            #SchemaMap.domains
components:         #SchemaMap.components
artifacts:          #SchemaMap.artifacts
interfaces:         #SchemaMap.interfaces
relationships:      #SchemaMap.relationships
capabilities:       #SchemaMap.capabilities
validationProfiles: #SchemaMap.validationProfiles

let modelRepository = repository
let modelDomains = domains
let modelComponents = components
let modelArtifacts = artifacts
let modelRelationships = relationships
let modelCapabilities = capabilities
let modelValidationProfiles = validationProfiles

#AgentCapabilityRoute: {
	terms: [...string]
	searchRoots: [...#SchemaMapRelativePath]
	artifacts: [...#SchemaMapIdentifier]
	validationProfiles: [...#SchemaMapIdentifier]
}

#AgentCapabilityRoutes: [#SchemaMapIdentifier]: #AgentCapabilityRoute

agentCapabilityRoutes: #AgentCapabilityRoutes & {
	"desktop-session-lifecycle": {
		terms: [
			"lock",
			"unlock",
			"lockout",
			"osd",
			"brightness",
			"hypr",
			"pomodoro",
			"tomat",
		]
		searchRoots: [
			"chezmoi/private_dot_config/hypr",
			"shell-wrap/src/session/src",
			"shell-wrap/src/session/system",
		]
		artifacts: [
			"hypr-config-source",
			"session-bashly-source",
			"session-generated-executable",
			"session-symlink-template",
		]
		validationProfiles: [
			"session-bashly",
			"chezmoi-closeout",
		]
	}
	"workspace-lifecycle": {
		terms: [
			"wezterm",
			"workspace",
			"sessionizer",
			"smart-splits",
			"smart_splits",
			"project catalog",
			"project discovery",
		]
		searchRoots: [
			"chezmoi/private_dot_config/wezterm",
			"chezmoi/private_dot_config/xplr",
			"chezmoi/private_dot_config/nvim",
		]
		artifacts: [
			"wezterm-config-source",
			"nvim-config-source",
			"xplr-config-source",
			"wezterm-smart-splits-lua",
			"nvim-smart-splits-config",
		]
		validationProfiles: ["chezmoi-closeout"]
	}
}

#CapabilityMatchInput: {
	prompt: string
	matches: [
		for capabilityID, route in agentCapabilityRoutes
		let matchedTerms = [
			for term in route.terms
			if strings.Contains(strings.ToLower(prompt), term) {
				term
			},
		]
		if len(matchedTerms) > 0 {
			id:    capabilityID
			terms: matchedTerms
		},
	]
}

hookInput: {
	hook_event_name: "UserPromptSubmit"
	prompt:          string | *""
	...
}

hookMatch: #CapabilityMatchInput & {
	prompt: hookInput.prompt
}

#RoutingHint: {
	schema:    "agent.hook-hint.v1"
	system:    "dotfiles.schema-map.v1"
	directive: string
	candidates: [...#SchemaMapIdentifier]
	matchedTerms: [...string]
	resolver: {
		tool:            string
		fallbackCommand: string
		skill:           #SchemaMapRelativePath
	}
}

if len(hookMatch.matches) == 1 {
	let match = hookMatch.matches[0]

	routingHint: #RoutingHint & {
		schema:    "agent.hook-hint.v1"
		system:    "dotfiles.schema-map.v1"
		directive: "This is a routing hint, not task context. Before repository inspection or editing, read the named protocol skill and invoke resolve-agent-context. Use only the returned CUE projection as the task map."
		candidates: [match.id]
		matchedTerms: match.terms
		resolver: {
			tool:            "cue.resolve_agent_context"
			fallbackCommand: ".codex/skills/resolve-agent-context/scripts/resolve-agent-context"
			skill:           ".codex/skills/resolve-agent-context/SKILL.md"
		}
	}

	userPromptHookOutput: {
		hookSpecificOutput: {
			hookEventName:     "UserPromptSubmit"
			additionalContext: "Agent context routing hint:\n\(json.Marshal(routingHint))"
		}
	}
}

if len(hookMatch.matches) != 1 {
	userPromptHookOutput: {}
}

resolverInput: {
	prompt: string | *""
	cwd:    #SchemaMapAbsolutePath | *modelRepository.root
	candidateCapabilities: [...#SchemaMapIdentifier] | *[]
}

resolverPromptMatch: #CapabilityMatchInput & {
	prompt: resolverInput.prompt
}

resolverCandidateMatches: [
	for match in resolverPromptMatch.matches
	if list.Contains(resolverInput.candidateCapabilities, match.id) {
		match
	},
]

resolverMatches: [...{
	id: #SchemaMapIdentifier
	terms: [...string]
}] | *[]
if len(resolverPromptMatch.matches) == 1 {
	resolverMatches: resolverPromptMatch.matches
}
if len(resolverPromptMatch.matches) > 1 {
	resolverMatches: resolverCandidateMatches
}

mutationTerms: [
	"fix",
	"change",
	"update",
	"add",
	"remove",
	"edit",
	"implement",
	"refactor",
	"adapt",
	"regenerate",
]

matchedMutationTerms: [
	for term in mutationTerms
	if list.Contains(strings.Fields(strings.ToLower(resolverInput.prompt)), term) {
		term
	},
]

resolverMode: "read-only" | "mutation"
if len(matchedMutationTerms) == 0 {
	resolverMode: "read-only"
}
if len(matchedMutationTerms) > 0 {
	resolverMode: "mutation"
}

#AgentContextProjection: {
	schema: "agent.context-projection.v1"
	decision: {
		capability: #SchemaMapIdentifier
		mode:       "read-only" | "mutation"
		confidence: "high"
		matchedTerms: [...string]
	}
	project: {
		id:   #SchemaMapIdentifier
		root: #SchemaMapAbsolutePath
		cwd:  #SchemaMapAbsolutePath
	}
	scope: {
		inspect: [...#SchemaMapRelativePath]
		instructionBoundaries: [...#SchemaMapRelativePath]
	}
	boundaries: {
		source: [...#SchemaMapRelativePath]
		generated: [...#SchemaMapRelativePath]
	}
	components: [...{
		id:   #SchemaMapIdentifier
		root: #SchemaMapRelativePath
		entrypoints: [...#SchemaMapRelativePath]
	}]
	artifacts: [...{
		id:   #GraphID
		path: #SchemaMapRelativePath
	}]
	relationships: [...{
		from: #SchemaMapIdentifier
		type: string
		to:   #SchemaMapIdentifier
		via?: string
	}]
	validation: {
		required: bool
		reason:   string
		commands: [...{
			argv: [...string]
			cwd:     #SchemaMapRelativePath | "."
			purpose: string
		}]
	}
	mutationPolicy: {
		edit:       "source"
		regenerate: "generated"
		neverEditDirectly: [...#SchemaMapRelativePath]
	}
	instructions: [...string]
}

if len(resolverMatches) == 1 {
	let match = resolverMatches[0]
	let selectedCapability = modelCapabilities[match.id]
	let route = agentCapabilityRoutes[match.id]

	agentContextProjection: #AgentContextProjection & {
		schema: "agent.context-projection.v1"
		decision: {
			capability:   selectedCapability.id
			mode:         resolverMode
			confidence:   "high"
			matchedTerms: match.terms
		}
		project: {
			id:   modelRepository.id
			root: modelRepository.root
			cwd:  resolverInput.cwd
		}
		scope: {
			inspect: route.searchRoots
			instructionBoundaries: [
				for boundary in modelRepository.instructionBoundaries
				if len([
					for domainID in selectedCapability.references.domains
					if modelDomains[domainID].root == boundary.scope {
						domainID
					},
				]) > 0 {
					boundary.path
				},
			]
		}
		boundaries: {
			source: [
				for artifactID in route.artifacts
				if modelArtifacts[artifactID].authority == "source" {
					modelArtifacts[artifactID].path
				},
			]
			generated: [
				for artifactID in route.artifacts
				if modelArtifacts[artifactID].authority == "generated" {
					modelArtifacts[artifactID].path
				},
			]
		}
		components: [
			for componentID in selectedCapability.references.components {
				id:          modelComponents[componentID].id
				root:        modelComponents[componentID].root
				entrypoints: modelComponents[componentID].entrypoints
			},
		]
		artifacts: [
			for artifactID in route.artifacts {
				id:   "df:artifact/\(artifactID)"
				path: modelArtifacts[artifactID].path
			},
		]
		relationships: [
			for relationshipID in selectedCapability.references.relationships {
				from: modelRelationships[relationshipID].from
				type: modelRelationships[relationshipID].type
				to:   modelRelationships[relationshipID].to
				if modelRelationships[relationshipID].via != _|_ {
					via: modelRelationships[relationshipID].via
				}
			},
		]
		validation: {
			if resolverMode == "read-only" {
				required: false
				reason:   "Read-only task; mutation validation is not active."
				commands: []
			}
			if resolverMode == "mutation" {
				required: true
				reason:   "Mutation task; validate authoritative sources and generated boundaries."
				commands: [
					for profileID in route.validationProfiles
					for command in modelValidationProfiles[profileID].commands {
						command
					},
				]
			}
		}
		mutationPolicy: {
			edit:       "source"
			regenerate: "generated"
			neverEditDirectly: [
				for artifactID in route.artifacts
				if modelArtifacts[artifactID].editable == false {
					modelArtifacts[artifactID].path
				},
			]
		}
		instructions: [
			"Use this CUE projection as the task map.",
			"Inspect only projected roots and entrypoints unless evidence requires a bounded expansion.",
			"Read projected instruction boundaries before editing.",
			"Do not edit generated .codex files; regenerate them from contract.cuemod.",
		]
	}
}

agentSkillProvenance: agentskill.#ProjectionProvenance & {
	projection_id: "df:projection/resolve-agent-context-skill"
	contract_ids: ["df:contract/agent-skill-runtime"]
	generated: true
}

codexHooks: agentskill.#HookProjection & {
	hooks: {
		UserPromptSubmit: [{
			hooks: [{
				type:          "command"
				command:       ".codex/skills/resolve-agent-context/scripts/dotfiles-agent-context-hook"
				timeout:       10
				statusMessage: "Routing dotfiles capability context"
			}]
		}]
	}
}

codexSkill: """
	---
	name: resolve-agent-context
	description: Resolve authoritative CUE task context before inspecting or editing dotfiles capabilities when a hook routing hint names this skill or the resolve-agent-context command.
	---

	# Agent Context Resolution

	The hook hint is not task context. It contains candidate capability IDs only.

	Before repository inspection or editing, call the CUE MCP resolver:

	```text
	cue.resolve_agent_context({
	  "prompt": "<current user prompt>",
	  "cwd": "<current working directory>",
	  "candidates": ["<candidate capability from the hook hint>"]
	})
	```

	Use the returned CUE projection as the task map and retain its `projection_id`.

	- Resolve first; inspect second.
	- For implementation evidence, select graph artifact IDs from the projection and call `cue.search_implementation` with `projection_id` and `artifact_ids`; do not invoke `rg` directly.
	- `cue.search_implementation` is an MCP tool registered by the Go runtime, not a `cue cmd` command. CUE authorizes its internal search plan before Go executes `rg`.
	- Cite returned evidence IDs with exact paths and lines.
	- Treat hook candidates as hints, never authority.
	- Do not invoke `cue cmd` directly or hand-write temporary CUE input.
	- Use `.codex/skills/resolve-agent-context/scripts/resolve-agent-context` only as an explicitly reported Stage 2 fallback when the CUE MCP server is unavailable.
	- Do not infer source/generated boundaries from the hook.
	- Do not edit generated `.codex/hooks.json` or `.codex/skills/*`; regenerate them from `contract.cuemod`.
	- Run validation commands only when `validation.required` is `true`.
	"""

agentContextHookScript: agentskill.#ScriptAsset & {
	path:       ".codex/skills/resolve-agent-context/scripts/dotfiles-agent-context-hook"
	executable: true
	provenance: agentSkillProvenance
	content: """
		#!/bin/sh
		set -eu

		script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
		contract_root=${CONTRACT_CUEMOD_ROOT:-${CONTRACT_ROOT:-${DOTFILES_CONTRACT_ROOT:-$(CDPATH= cd -- "$script_dir/../../../.." && pwd -P)}}}
		input_json=$(mktemp "${TMPDIR:-/tmp}/dotfiles-agent-context.XXXXXX.json")
		wrapped_json=$(mktemp "${TMPDIR:-/tmp}/dotfiles-agent-context-wrapped.XXXXXX.json")

		cleanup() {
			rm -f "$input_json" "$wrapped_json"
		}
		trap cleanup EXIT HUP INT TERM

		cat >"$input_json"
		jq -c '{hookInput: .}' "$input_json" >"$wrapped_json"

		cd "$contract_root"
		cue export . dotfiles.schema-map.json "$wrapped_json" -e userPromptHookOutput
		"""
}

resolveAgentContextScript: agentskill.#ScriptAsset & {
	path:       ".codex/skills/resolve-agent-context/scripts/resolve-agent-context"
	executable: true
	provenance: agentSkillProvenance
	content: """
		#!/bin/sh
		set -eu

		script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
		contract_root=${CONTRACT_CUEMOD_ROOT:-${CONTRACT_ROOT:-${DOTFILES_CONTRACT_ROOT:-$(CDPATH= cd -- "$script_dir/../../../.." && pwd -P)}}}
		prompt=
		cwd=$PWD
		candidates_json='[]'

		while [ "$#" -gt 0 ]; do
			case $1 in
			--prompt)
				[ "$#" -ge 2 ] || {
					printf 'resolve-agent-context: --prompt requires a value\\n' >&2
					exit 2
				}
				prompt=$2
				shift 2
				;;
			--cwd)
				[ "$#" -ge 2 ] || {
					printf 'resolve-agent-context: --cwd requires a value\\n' >&2
					exit 2
				}
				cwd=$2
				shift 2
				;;
			--candidate)
				[ "$#" -ge 2 ] || {
					printf 'resolve-agent-context: --candidate requires a value\\n' >&2
					exit 2
				}
				candidates_json=$(jq -c --arg candidate "$2" '. + [$candidate]' <<EOF
		$candidates_json
		EOF
		)
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

		input_json=$(mktemp "${TMPDIR:-/tmp}/resolve-agent-context.XXXXXX.json")
		cleanup() {
			rm -f "$input_json"
		}
		trap cleanup EXIT HUP INT TERM

		jq -n \\
			--arg prompt "$prompt" \\
			--arg cwd "$cwd" \\
			--argjson candidates "$candidates_json" \\
			'{resolverInput: {prompt: $prompt, cwd: $cwd, candidateCapabilities: $candidates}}' \\
			>"$input_json"

		cd "$contract_root"
		cue export . dotfiles.schema-map.json "$input_json" -e agentContextProjection
		"""
}
