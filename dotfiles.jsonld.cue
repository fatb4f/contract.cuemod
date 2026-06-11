package workspace

import "list"

#IRI:          string & =~"^df:[a-z]+/[a-z0-9._-]+$"
#RelativePath: string & !~"^/"

#JSONLDContext: string | {
	[string]: string | {
		"@id":    string
		"@type"?: string
	}
}

#Artifact: {
	id:       #IRI
	type:     "Artifact"
	path:     #RelativePath
	language: string
	role:     string
}

#Node: {
	id:      #IRI
	type:    "Node"
	surface: "wezterm" | "nvim" | "xplr" | "zsh" | "hypr" | "chezmoi"
	role:    string

	artifacts: [...#IRI] | *[]
	produces: [...#IRI] | *[]
	consumes: [...#IRI] | *[]
}

#Interface: {
	id:   #IRI
	type: "Interface"
	kind: "env-var" | "socket" | "user-var" | "key-vector" | "cli" | "filesystem-path" | "lua-module"
	name: string

	payload?: {
		env?: [...string]
		userVars?: [...string]
		keys?: [...string]
		paths?: [...string]
		commands?: [...string]
	}
}

#Invariant: {
	id:        #IRI
	statement: string
}

#Contract: {
	id:   #IRI
	type: "Contract"
	kind: "ide-lifecycle" | "pane-navigation" | "session-selection" | "materialization" | "shell-environment"

	participants: [#IRI, #IRI, ...#IRI]
	interfaces: [#IRI, ...#IRI]
	invariants?: [...#Invariant]
}

#Relationship: {
	id:   #IRI
	type: "Relationship"
	kind: "imports" | "spawns" | "sets" | "reads" | "adapts" | "forwards" | "materializes" | "validates"

	from: #IRI
	to:   #IRI

	interfaces: [...#IRI] | *[]
	fulfills: #IRI
	evidence: [#IRI, ...#IRI]
}

#Evidence: {
	id:   #IRI
	type: "Evidence"

	artifact:  #IRI
	file:      #RelativePath
	line?:     int & >=1
	column?:   int & >=1
	symbol?:   string
	statement: string

	typeSystem?:  "lua-language-server" | "tree-sitter" | "runtime-observed"
	typeLibrary?: string
	confidence:   "observed" | "annotated" | "generated"
}

#ImplementationKind:
	"lua-module" |
	"plugin" |
	"config-fragment" |
	"runtime-binding" |
	"event-handler" |
	"action-binding" |
	"key-binding" |
	"pane-binding" |
	"window-binding" |
	"mux-binding" |
	"type-library"

#TypedSymbol: {
	id:   #IRI
	type: "TypedSymbol"
	name: string

	typeSystem:   "lua-language-server" | "tree-sitter" | "runtime-observed"
	typeLibrary?: string

	configType?:   string
	runtimeType?:  string
	contractType?: string

	location?: {
		file:    #RelativePath
		line?:   int & >=1
		column?: int & >=1
	}
}

#ImplementationObject: {
	id:       #IRI
	type:     "ImplementationObject"
	kind:     #ImplementationKind
	surface:  "wezterm" | "nvim" | "xplr" | "zsh" | "hypr"
	artifact: #IRI

	symbols: [...#TypedSymbol] | *[]
	provides: [...#IRI] | *[]
	consumes: [...#IRI] | *[]
	fulfills: [...#IRI] | *[]
	evidence: [#IRI, ...#IRI]
}

#GraphObject:
	#Artifact |
	#Node |
	#Interface |
	#Contract |
	#Relationship |
	#Evidence |
	#ImplementationObject

#JSONLDDocument: {
	"@context": #JSONLDContext
	graph="@graph": [...#GraphObject]

	_nodeArtifactsResolve:           true
	_nodeProducedInterfacesResolve:  true
	_nodeConsumedInterfacesResolve:  true
	_contractParticipantsResolve:    true
	_contractParticipantsFulfill:    true
	_contractInterfacesResolve:      true
	_relationshipSourcesResolve:     true
	_relationshipTargetsResolve:     true
	_relationshipContractsResolve:   true
	_relationshipInterfacesResolve:  true
	_relationshipEvidenceResolves:   true
	_evidenceArtifactsResolve:       true
	_implementationArtifactsResolve: true
	_implementationProvidesResolve:  true
	_implementationConsumesResolve:  true
	_implementationContractsResolve: true
	_implementationEvidenceResolves: true

	let nodeIDs = [
		for object in graph
		if object.type == "Node" {
			object.id
		},
	]
	let interfaceIDs = [
		for object in graph
		if object.type == "Interface" {
			object.id
		},
	]
	let contractIDs = [
		for object in graph
		if object.type == "Contract" {
			object.id
		},
	]
	let artifactIDs = [
		for object in graph
		if object.type == "Artifact" {
			object.id
		},
	]
	let evidenceIDs = [
		for object in graph
		if object.type == "Evidence" {
			object.id
		},
	]

	for object in graph {
		if object.type == "Node" {
			for artifact in object.artifacts {
				if !list.Contains(artifactIDs, artifact) {
					_nodeArtifactsResolve: false
				}
			}
			for interface in object.produces {
				if !list.Contains(interfaceIDs, interface) {
					_nodeProducedInterfacesResolve: false
				}
			}
			for interface in object.consumes {
				if !list.Contains(interfaceIDs, interface) {
					_nodeConsumedInterfacesResolve: false
				}
			}
		}
		if object.type == "Contract" {
			for participant in object.participants {
				if !list.Contains(nodeIDs, participant) {
					_contractParticipantsResolve: false
				}
				let fulfillingRelationships = [
					for relationship in graph
					if relationship.type == "Relationship"
					if relationship.fulfills == object.id
					if relationship.from == participant || relationship.to == participant {
						relationship.id
					},
				]
				if len(fulfillingRelationships) == 0 {
					_contractParticipantsFulfill: false
				}
			}
			for interface in object.interfaces {
				if !list.Contains(interfaceIDs, interface) {
					_contractInterfacesResolve: false
				}
			}
		}
		if object.type == "Relationship" {
			if !list.Contains(nodeIDs, object.from) {
				_relationshipSourcesResolve: false
			}
			if !list.Contains(nodeIDs, object.to) {
				_relationshipTargetsResolve: false
			}
			if !list.Contains(contractIDs, object.fulfills) {
				_relationshipContractsResolve: false
			}
			for interface in object.interfaces {
				if !list.Contains(interfaceIDs, interface) {
					_relationshipInterfacesResolve: false
				}
			}
			for evidence in object.evidence {
				if !list.Contains(evidenceIDs, evidence) {
					_relationshipEvidenceResolves: false
				}
			}
		}
		if object.type == "Evidence" {
			if !list.Contains(artifactIDs, object.artifact) {
				_evidenceArtifactsResolve: false
			}
		}
		if object.type == "ImplementationObject" {
			if !list.Contains(artifactIDs, object.artifact) {
				_implementationArtifactsResolve: false
			}
			for interface in object.provides {
				if !list.Contains(interfaceIDs, interface) {
					_implementationProvidesResolve: false
				}
			}
			for interface in object.consumes {
				if !list.Contains(interfaceIDs, interface) {
					_implementationConsumesResolve: false
				}
			}
			for contract in object.fulfills {
				if !list.Contains(contractIDs, contract) {
					_implementationContractsResolve: false
				}
			}
			for evidence in object.evidence {
				if !list.Contains(evidenceIDs, evidence) {
					_implementationEvidenceResolves: false
				}
			}
		}
	}
}

jsonldContext: {
	"df":   "https://fatb4f.dev/dotfiles#"
	"id":   "@id"
	"type": "@type"

	"Contract":             "df:Contract"
	"Interface":            "df:Interface"
	"Node":                 "df:Node"
	"Artifact":             "df:Artifact"
	"Relationship":         "df:Relationship"
	"Evidence":             "df:Evidence"
	"ImplementationObject": "df:ImplementationObject"
	"TypedSymbol":          "df:TypedSymbol"

	"participants": {"@id": "df:participants", "@type": "@id"}
	"interfaces": {"@id": "df:interfaces", "@type": "@id"}
	"artifacts": {"@id": "df:artifacts", "@type": "@id"}
	"evidence": {"@id": "df:evidence", "@type": "@id"}
	"from": {"@id": "df:from", "@type": "@id"}
	"to": {"@id": "df:to", "@type": "@id"}
	"fulfills": {"@id": "df:fulfills", "@type": "@id"}
	"consumes": {"@id": "df:consumes", "@type": "@id"}
	"produces": {"@id": "df:produces", "@type": "@id"}
	"provides": {"@id": "df:provides", "@type": "@id"}
}
