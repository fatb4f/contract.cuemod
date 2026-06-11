package workspace

#SchemaMapRelativePath: string & !~"^/"
#SchemaMapAbsolutePath: string & =~"^/"
#SchemaMapIdentifier:   string & =~"^[a-z0-9][a-z0-9._-]*$"

#SchemaMapEvidence: {
	path:  #SchemaMapRelativePath
	line?: int & >=1
	note?: string
}

#SchemaMapReferenceSet: {
	domains: [...#SchemaMapIdentifier] | *[]
	components: [...#SchemaMapIdentifier] | *[]
	artifacts: [...#SchemaMapIdentifier] | *[]
	interfaces: [...#SchemaMapIdentifier] | *[]
	relationships: [...#SchemaMapIdentifier] | *[]
	validationProfiles: [...#SchemaMapIdentifier] | *[]
}

#SchemaMapCapabilityProjection: {
	id:         #SchemaMapIdentifier
	title:      string
	purpose:    string
	references: #SchemaMapReferenceSet
	agentUse: [...string]
	children?: [#SchemaMapIdentifier]: #SchemaMapCapabilityProjection
}

#SchemaMapDomain: {
	id:    #SchemaMapIdentifier
	title: string
	root:  #SchemaMapRelativePath | "."
	kind:  "materializer" | "configuration" | "executable-source" | "repository"
	languages: [...string]
	instructionEntry?: #SchemaMapRelativePath
	owns: [...string]
}

#SchemaMapComponent: {
	id:     #SchemaMapIdentifier
	title:  string
	domain: #SchemaMapIdentifier
	kind:   string
	root:   #SchemaMapRelativePath
	entrypoints: [...#SchemaMapRelativePath]
	responsibilities: [...string]
	confidence: "observed" | "annotated"
	evidence: [...#SchemaMapEvidence]
}

#SchemaMapArtifact: {
	id:          #SchemaMapIdentifier
	domain:      #SchemaMapIdentifier
	kind:        "source" | "generated" | "template" | "target"
	path:        #SchemaMapRelativePath
	targetPath?: string
	authority:   "source" | "generated" | "runtime"
	editable:    bool
	evidence?: [...#SchemaMapEvidence]
}

#SchemaMapInterface: {
	id:   #SchemaMapIdentifier
	kind: "environment" | "command" | "file" | "socket" | "module"
	name: string
	producers: [...#SchemaMapIdentifier]
	consumers: [...#SchemaMapIdentifier]
	purpose:  string
	lifetime: "configuration" | "workspace" | "process" | "runtime"
	evidence: [...#SchemaMapEvidence]
}

#SchemaMapRelationship: {
	id:         #SchemaMapIdentifier
	from:       #SchemaMapIdentifier
	type:       "loads" | "materializes" | "generates" | "launches" | "invokes" | "consumes" | "integrates-with"
	to:         #SchemaMapIdentifier
	via?:       string
	confidence: "observed" | "annotated"
	evidence: [...#SchemaMapEvidence]
}

#SchemaMapValidationProfile: {
	id:    #SchemaMapIdentifier
	scope: #SchemaMapReferenceSet
	commands: [...{
		argv: [...string]
		cwd:     #SchemaMapRelativePath | "."
		purpose: string
	}]
}

#SchemaMap: {
	version: "dotfiles.schema-map.v1"
	repository: {
		id:            "dotfiles"
		root:          #SchemaMapAbsolutePath
		kind:          "polyglot-dotfiles"
		sourceOfTruth: "live-implementation"
		languages: [...string]
		instructionBoundaries: [...{
			path:  #SchemaMapRelativePath
			scope: #SchemaMapRelativePath
		}]
	}
	domains: [#SchemaMapIdentifier]:            #SchemaMapDomain
	components: [#SchemaMapIdentifier]:         #SchemaMapComponent
	artifacts: [#SchemaMapIdentifier]:          #SchemaMapArtifact
	interfaces: [#SchemaMapIdentifier]:         #SchemaMapInterface
	relationships: [#SchemaMapIdentifier]:      #SchemaMapRelationship
	capabilities: [#SchemaMapIdentifier]:       #SchemaMapCapabilityProjection
	validationProfiles: [#SchemaMapIdentifier]: #SchemaMapValidationProfile
	agentContext: {
		defaultProjection: #SchemaMapIdentifier
		selectionRule:     string
		requiredFields: [...string]
	}
}
