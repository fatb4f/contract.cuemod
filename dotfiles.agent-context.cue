package workspace

import (
	"encoding/json"
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
			"project catalog",
			"project discovery",
		]
		artifacts: ["wezterm-config-source"]
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
		command: string
		skill:   #SchemaMapRelativePath
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
			command: "/home/_404/src/contract.cuemod/bin/resolve-agent-context"
			skill:   ".codex/skills/resolve-agent-context/SKILL.md"
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
	if strings.Contains(strings.ToLower(resolverInput.prompt), term) {
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
			inspect: [
				for componentID in selectedCapability.references.components {
					modelComponents[componentID].root
				},
			]
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

codexHooks: {
	hooks: {
		UserPromptSubmit: [{
			hooks: [{
				type:          "command"
				command:       "/home/_404/src/contract.cuemod/bin/dotfiles-agent-context-hook"
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

	Before repository inspection or editing, run the stable resolver:

	```sh
	/home/_404/src/contract.cuemod/bin/resolve-agent-context \\
	  --prompt "<current user prompt>" \\
	  --cwd "$PWD" \\
	  --candidate "<candidate capability from the hook hint>"
	```

	Use the returned CUE projection as the task map.

	- Resolve first; inspect second.
	- Treat hook candidates as hints, never authority.
	- Do not invoke `cue cmd` directly or hand-write temporary CUE input.
	- Do not infer source/generated boundaries from the hook.
	- Do not edit generated `.codex/hooks.json` or `.codex/skills/*`; regenerate them from `contract.cuemod`.
	- Run validation commands only when `validation.required` is `true`.
	"""
