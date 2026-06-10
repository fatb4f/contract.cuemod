package workspace

import (
	"encoding/json"
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
let modelInterfaces = interfaces
let modelRelationships = relationships
let modelCapabilities = capabilities
let modelValidationProfiles = validationProfiles

hookInput: {
	hook_event_name: "UserPromptSubmit"
	prompt:          string | *""
	...
}

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
		artifacts: [
			"wezterm-config-source",
		]
		validationProfiles: [
			"chezmoi-closeout",
		]
	}
}

_prompt: strings.ToLower(hookInput.prompt)

_capabilityMatches: [
	for capabilityID, route in agentCapabilityRoutes
	let matchedTerms = [
		for term in route.terms
		if strings.Contains(_prompt, term) {
			term
		},
	]
	if len(matchedTerms) > 0 {
		id:    capabilityID
		terms: matchedTerms
	},
]

#AgentContextProjection: {
	schema: "dotfiles.agent-context.v1"
	capability: {
		id:      #SchemaMapIdentifier
		title:   string
		purpose: string
		matchedTerms: [...string]
	}
	repository: {
		id:   #SchemaMapIdentifier
		root: #SchemaMapAbsolutePath
		instructionBoundaries: [...{
			path:  #SchemaMapRelativePath
			scope: #SchemaMapRelativePath
		}]
	}
	domains: [...{
		id:                #SchemaMapIdentifier
		title:             string
		root:              #SchemaMapRelativePath | "."
		kind:              string
		instructionEntry?: #SchemaMapRelativePath
	}]
	components: [...{
		id:     #SchemaMapIdentifier
		title:  string
		domain: #SchemaMapIdentifier
		kind:   string
		root:   #SchemaMapRelativePath
		entrypoints: [...#SchemaMapRelativePath]
		responsibilities: [...string]
	}]
	artifacts: [...{
		id:          #SchemaMapIdentifier
		domain:      #SchemaMapIdentifier
		kind:        string
		path:        #SchemaMapRelativePath
		targetPath?: string
		authority:   string
		editable:    bool
	}]
	interfaces: [...{
		id:       #SchemaMapIdentifier
		kind:     string
		name:     string
		purpose:  string
		lifetime: string
	}]
	relationships: [...{
		id:   #SchemaMapIdentifier
		from: #SchemaMapIdentifier
		type: string
		to:   #SchemaMapIdentifier
		via?: string
	}]
	requiredWorkflows: [...{
		id: #SchemaMapIdentifier
		commands: [...{
			argv: [...string]
			cwd:     #SchemaMapRelativePath | "."
			purpose: string
		}]
	}]
	agentUse: [...string]
	directive: string
}

if len(_capabilityMatches) == 1 {
	let match = _capabilityMatches[0]
	let selectedCapability = modelCapabilities[match.id]
	let route = agentCapabilityRoutes[match.id]

	agentContextProjection: #AgentContextProjection & {
		schema: "dotfiles.agent-context.v1"
		capability: {
			id:           selectedCapability.id
			title:        selectedCapability.title
			purpose:      selectedCapability.purpose
			matchedTerms: match.terms
		}
		repository: {
			id:   modelRepository.id
			root: modelRepository.root
			instructionBoundaries: [
				for boundary in modelRepository.instructionBoundaries
				if len([
					for domainID in selectedCapability.references.domains
					if modelDomains[domainID].root == boundary.scope {
						domainID
					},
				]) > 0 {
					boundary
				},
			]
		}
		domains: [
			for domainID in selectedCapability.references.domains {
				id:    modelDomains[domainID].id
				title: modelDomains[domainID].title
				root:  modelDomains[domainID].root
				kind:  modelDomains[domainID].kind
				if modelDomains[domainID].instructionEntry != _|_ {
					instructionEntry: modelDomains[domainID].instructionEntry
				}
			},
		]
		components: [
			for componentID in selectedCapability.references.components {
				id:               modelComponents[componentID].id
				title:            modelComponents[componentID].title
				domain:           modelComponents[componentID].domain
				kind:             modelComponents[componentID].kind
				root:             modelComponents[componentID].root
				entrypoints:      modelComponents[componentID].entrypoints
				responsibilities: modelComponents[componentID].responsibilities
			},
		]
		artifacts: [
			for artifactID in route.artifacts {
				id:        modelArtifacts[artifactID].id
				domain:    modelArtifacts[artifactID].domain
				kind:      modelArtifacts[artifactID].kind
				path:      modelArtifacts[artifactID].path
				authority: modelArtifacts[artifactID].authority
				editable:  modelArtifacts[artifactID].editable
				if modelArtifacts[artifactID].targetPath != _|_ {
					targetPath: modelArtifacts[artifactID].targetPath
				}
			},
		]
		interfaces: [
			for interfaceID in selectedCapability.references.interfaces {
				id:       modelInterfaces[interfaceID].id
				kind:     modelInterfaces[interfaceID].kind
				name:     modelInterfaces[interfaceID].name
				purpose:  modelInterfaces[interfaceID].purpose
				lifetime: modelInterfaces[interfaceID].lifetime
			},
		]
		relationships: [
			for relationshipID in selectedCapability.references.relationships {
				id:   modelRelationships[relationshipID].id
				from: modelRelationships[relationshipID].from
				type: modelRelationships[relationshipID].type
				to:   modelRelationships[relationshipID].to
				if modelRelationships[relationshipID].via != _|_ {
					via: modelRelationships[relationshipID].via
				}
			},
		]
		requiredWorkflows: [
			for profileID in route.validationProfiles {
				id:       modelValidationProfiles[profileID].id
				commands: modelValidationProfiles[profileID].commands
			},
		]
		agentUse:  selectedCapability.agentUse
		directive: "Use this capability projection as the task map. Read applicable instruction boundaries before editing. Treat artifact authority and editable fields as constraints. Perform fresh inspection only inside the projected roots, then run the required workflows."
	}

	userPromptHookOutput: {
		hookSpecificOutput: {
			hookEventName:     "UserPromptSubmit"
			additionalContext: "Dotfiles capability context:\n\(json.Marshal(agentContextProjection))"
		}
	}
}

if len(_capabilityMatches) != 1 {
	userPromptHookOutput: {}
}

codexHooks: {
	hooks: {
		UserPromptSubmit: [{
			hooks: [{
				type:          "command"
				command:       "/home/_404/src/contract.cuemod/bin/dotfiles-agent-context-hook"
				timeout:       10
				statusMessage: "Resolving dotfiles capability context"
			}]
		}]
	}
}
