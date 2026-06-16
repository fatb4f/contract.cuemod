package graph

#ID: string & =~"^[a-z0-9][a-z0-9._-]*$"

#RelPath: string & !="" & !~"^/" & !~"(^|/)\\.\\.(/|$)"

#ObjectModelKind:
	"contract-object-model" |
	"functional-domain" |
	"artifact-domain" |
	"adapter-domain" |
	"projection-domain"

#ContractSectionKind:
	"assertions" |
	"fixtures" |
	"adapters" |
	"projections" |
	"generated" |
	"seeds" |
	"workers" |
	"checks" |
	"hooks"

#ContractLeafKind:
	"assertion" |
	"fixture" |
	"adapter" |
	"projection" |
	"generated" |
	"seed" |
	"worker" |
	"check" |
	"hook" |
	"migration"

#AuthorityEdgeKind:
	"owns" |
	"contains"

#RelationEdgeKind:
	"asserts" |
	"evidences" |
	"validates" |
	"derives" |
	"projects" |
	"executes" |
	"guards" |
	"depends_on" |
	"adapts" |
	"blocks"

#AssertionPolarity:
	"positive" |
	"negative" |
	"invariant"

#AssertionStrength:
	"required" |
	"recommended" |
	"temporary" |
	"migration"

#CheckKind:
	"cue-vet" |
	"cue-export" |
	"cue-def" |
	"shell" |
	"negative-cue-vet" |
	"fixture-polarity" |
	"generated-freshness" |
	"hook-regression" |
	"worker-result"

#WorkerBindingKind:
	"projection-worker" |
	"fixture-worker" |
	"validation-worker" |
	"git-worker"

#WorkerBindingAction:
	"inspect" |
	"write_projection" |
	"write_fixture" |
	"mutate_source" |
	"run_validation" |
	"collect_evidence" |
	"inspect_git" |
	"stage" |
	"commit"

#ObjectModel: close({
	id:       #ID
	kind:     #ObjectModelKind
	package:  string & !=""
	rootPath: #RelPath

	description?: string & !=""
})

#AuthorityRoot: close({
	id:   #ID
	kind: "contract-root"
	path: #RelPath
	rootPath: [#ID, ...#ID]
})

#ContractSection: close({
	id:   #ID
	kind: #ContractSectionKind

	parent: #ID
	path:   #RelPath

	rootPath: [#ID, ...#ID]

	ownedLeaves: [...#ID]

	description?: string & !=""
})

#ContractLeaf: close({
	id:   #ID
	kind: #ContractLeafKind

	parent: #ID
	path:   #RelPath

	rootPath: [#ID, ...#ID]

	migration?: bool | *false

	description?: string & !=""
})

#AuthorityEdge: close({
	from: #ID
	to:   #ID
	kind: #AuthorityEdgeKind
})

#RelationEdge: close({
	from: #ID
	to:   #ID
	kind: #RelationEdgeKind

	description?: string & !=""
})

#Assertion: close({
	id:      #ID
	subject: #ID
	fact:    string & !=""

	appliesTo: [...#ID]
	evidence: [...#ID]

	polarity: #AssertionPolarity
	strength: #AssertionStrength | *"required"
	status:   "active" | "deprecated" | "planned" | *"active"

	description?: string & !=""
})

#Check: close({
	id:   #ID
	kind: #CheckKind

	assertions: [#ID, ...#ID]
	target: #ID

	command?: [...string & !=""]
	path?: #RelPath
	expr?: string & !=""

	failure: string & !=""
})

#WorkerPathScope: close({
	allowedPaths: [#RelPath, ...#RelPath]
	deniedPaths: [...#RelPath]
})

#WorkerBinding: close({
	id:   #ID
	kind: #WorkerBindingKind

	objective: string & !=""

	allowedNodes: [#ID, ...#ID]
	deniedNodes: [...#ID]

	requiredAssertions: [...#ID]

	pathScope?: #WorkerPathScope
	actions: [#WorkerBindingAction, ...#WorkerBindingAction]

	mayMutate:   bool | *false
	mayGenerate: bool | *false
	mayStage:    bool | *false
	mayCommit:   bool | *false

	resultAuthority: "evidence_only" | *"evidence_only"

	// Bind by contract instead of importing agent-runtime here. Importing
	// agent-runtime from graph would make downstream domain packages prone to
	// cycles because runtime contracts already import domain contracts.
	runtimeContract: "contracts/agent-runtime/sdk_workers.cue" | *"contracts/agent-runtime/sdk_workers.cue"
})

#HookBoundary: close({
	id: #ID
	kind:
		"pre-commit" |
		"pre-tool-use" |
		"post-tool-use" |
		"manual"

	guardsNodes: [...#ID]
	guardsPaths: [...#RelPath]

	requiredAssertions: [...#ID]
	worker: #ID

	onFailure:
		"block" |
		"warn" |
		"report"

	description?: string & !=""
})

#ContractDomain: close({
	id: #ID

	model: #ObjectModel
	root:  #AuthorityRoot

	sections: [ID=string]: #ContractSection & {
		id:     ID
		parent: root.id
		rootPath: [root.id, ID]
	}
	leaves: [ID=string]: #ContractLeaf & {
		id: ID
	}

	authorityEdges: [...#AuthorityEdge]
	relations: [...#RelationEdge]

	assertions: [ID=string]: #Assertion & {id: ID}
	checks: [ID=string]: #Check & {id: ID}
	workers: [ID=string]: #WorkerBinding & {id: ID}
	hooks: [ID=string]: #HookBoundary & {id: ID}

	model: id: id

	for _, worker in workers {
		if worker.kind == "validation-worker" && worker.mayMutate {
			_validationWorkerMutationDenied: _|_
		}
	}
})
