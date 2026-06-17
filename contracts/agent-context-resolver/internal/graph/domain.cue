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

#FixtureCaseKind:
	"positive" |
	"negative" |
	"invariant"

#ExpectedFixtureResult:
	"pass" |
	"fail"

#FixtureGenerationMode:
	"manual" |
	"generated" |
	"worker"

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

#WorkerRuntimeAdapter:
	"a2a" |
	"sdk-direct" |
	"mcp" |
	"cli"

#A2AWorkerAdapter: close({
	runtime:   "a2a"
	preferred: true

	offloadsContext:                  true
	offloadsRouteLocalResponsibility: true
	offloadsAuthority:                false

	inputAuthority:  "root_codex"
	resultAuthority: "evidence_only"

	description?: string & !=""
})

#WorkerProfile: close({
	id: #ID

	runtime:          #WorkerRuntimeAdapter | *"a2a"
	preferredRuntime: "a2a" | *"a2a"
	secondaryAdapters: [...#WorkerRuntimeAdapter] | *["sdk-direct", "mcp", "cli"]

	a2a: #A2AWorkerAdapter & {
		runtime:   "a2a"
		preferred: true
	}

	controlInvariants: [...string & !=""] | *[
		"Workers are predefined adapter-backed capabilities.",
		"Root Codex assigns bounded invocation packets.",
		"Workers return structured evidence.",
		"A2A offloads context and route-local responsibility.",
		"A2A does not offload authority.",
	]

	if runtime == "a2a" {
		preferredRuntime: "a2a"
	}
})

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

	coverageExempt: bool | *false

	description?: string & !=""
})

#FixtureObligation: close({
	id: #ID

	assertion: #ID
	polarity:  #FixtureCaseKind

	target: #ID
	path:   #RelPath

	expected: #ExpectedFixtureResult

	generation:    #FixtureGenerationMode | *"manual"
	worker?:       #ID
	targetPlanned: bool | *false

	description?: string & !=""
})

#TestObligation: close({
	id: #ID

	assertion: #ID
	fixtures: [...#ID]
	check: #ID

	command: [...string & !=""]

	description?: string & !=""
})

#AssertionCoverage: close({
	id:        #ID
	assertion: #ID

	requiredFixtures: [...#ID]
	requiredTests: [...#ID]

	status: "planned" | "active" | "deprecated" | *"active"
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

#CheckManifestEntry: close({
	id: #ID

	testObligation: #ID
	check:          #ID
	assertion:      #ID
	fixtures: [...#ID]

	command: [...string & !=""]

	evidenceRequired: {
		assertions: [#ID, ...#ID]
		fixtures: [...#ID]
		check: #ID
	}

	description?: string & !=""
})

#CheckManifest: close({
	id:     #ID
	domain: #ID

	entries: [ID=string]: #CheckManifestEntry & {
		id: ID
	}
})

#ValidationCertificateEntry: close({
	id: #ID

	manifestEntry:  #ID
	testObligation: #ID
	check:          #ID
	assertion:      #ID

	requiredEvidence: {
		assertions: [#ID, ...#ID]
		fixtures: [...#ID]
		check: #ID
		command: [...string & !=""]
	}

	runtimeEvidence?: {
		worker: #ID
		status: "pending" | "pass" | "fail" | "blocked"
		artifacts: [...#RelPath]
	}
})

#ValidationCertificate: close({
	id:     #ID
	domain: #ID

	manifest: #ID
	entries: [ID=string]: #ValidationCertificateEntry & {
		id: ID
	}
})

#WorkerPathScope: close({
	allowedPaths: [#RelPath, ...#RelPath]
	deniedPaths: [...#RelPath]
})

#WorkerBinding: close({
	id:   #ID
	kind: #WorkerBindingKind

	objective: string & !=""

	profile:        #WorkerProfile
	runtimeAdapter: #WorkerRuntimeAdapter | *profile.runtime

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

	protocolSurface?: close({
		responseItemMetadata: close({
			turn_id: "optional"
		})
		sourceIdentityRequired: true
		supportedEnvelopeKinds: ["NEW_TASK", "MESSAGE", "FINAL_ANSWER"]
		payloadBoundary: close({
			plaintextEnvelope:               true
			encryptedContent:                bool
			plaintextCarriesCorrelationOnly: true
			encryptedContentOpaque:          true
			definesGraphTruth:               false
			mutationAuthority:               false
		})
		authority:         "correlation_only"
		definesGraphTruth: false
		mutationAuthority: false
	})
})

#AdapterContract: close({
	schema?: "agent.adapter-contract.v1"
	id:      #ID
	runtime: #WorkerRuntimeAdapter
	worker:  #ID

	workerBindingID?:      #ID
	workerProfileID?:      #ID
	executesDeclaredWork?: true
	declaredActions: [#WorkerBindingAction, ...#WorkerBindingAction]
	routeIDs?: [...#ID]
	declaredRouteIDs?: [...#ID]
	supportedEnvelopeKinds?: [...("NEW_TASK" | "MESSAGE" | "FINAL_ANSWER")]
	payloadBoundary?: {
		plaintextEnvelope:               bool
		encryptedContent:                bool
		plaintextCarriesCorrelationOnly: true
		encryptedContentOpaque:          true
		definesGraphTruth:               false
		mutationAuthority:               false
	}

	inputAuthority:    "root_codex"
	resultAuthority:   "evidence_only"
	definesGraphTruth: false

	deny?: close({
		semanticAuthority?:      true
		graphTruthDefinition?:   true
		freeFormToolSelection?:  true
		unboundedRouteMutation?: true
	})

	description?: string & !=""
})

#EvidenceRecord: close({
	schema?: "agent.evidence-record.v1"
	id:      #ID
	kind:    "route-worker-evidence"

	routeID:            #ID
	workerID:           #ID
	profileID?:         #ID
	adapterID:          #ID
	invocationID:       #ID
	adapterExecutionID: #ID
	routeResultID:      #ID
	adapter?:           #WorkerRuntimeAdapter
	responseItemMetadata?: {
		turn_id?: string & !=""
	}
	sourceIdentity?: {
		sourceKind:      string & !=""
		sourceID:        #ID
		producerID?:     #ID
		responseItemID?: string & !=""
	}
	routeEnvelope?: {
		schema:     "codex.multi-agent.route-envelope.v2"
		kind:       "NEW_TASK" | "MESSAGE" | "FINAL_ANSWER"
		routeID:    #ID
		workerID?:  #ID
		adapterID?: #ID
		metadata?: {
			turn_id?: string & !=""
		}
		sourceIdentity: _
		taskName:       string & =~"^/[A-Za-z0-9._/-]+$"
		recipient:      string & =~"^/[A-Za-z0-9._/-]+$"
		sender:         string & =~"^/[A-Za-z0-9._/-]+$"
		payload: close({
			id: #ID
			kind:
				"task" |
				"message" |
				"final_answer" |
				"route_result" |
				"evidence"
		})
		payloadBoundary:   _
		authority:         "correlation_only"
		definesGraphTruth: false
		mutationAuthority: false
	}
	payloadBoundary?: {
		plaintextEnvelope:               bool
		encryptedContent:                bool
		plaintextCarriesCorrelationOnly: true
		encryptedContentOpaque:          true
		definesGraphTruth:               false
		mutationAuthority:               false
	}

	status:  "pass" | "fail" | "blocked" | "partial"
	summary: string & !=""
	observedEvidence?: [...]
	diagnostics?: [...string & !=""]

	reportsObservedResults:  true
	checksExpectedEvidence?: true
	authority:               "evidence_only"
	definesGraphTruth:       false
	mutationAuthority?:      false

	description?: string & !=""
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
	fixtureObligations: [ID=string]: #FixtureObligation & {
		id: ID
	}
	testObligations: [ID=string]: #TestObligation & {
		id: ID
	}
	coverage: [ID=string]: #AssertionCoverage & {
		id: ID
	}
	checks: [ID=string]: #Check & {id: ID}
	checkManifest?:         #CheckManifest
	validationCertificate?: #ValidationCertificate
	workers: [ID=string]: #WorkerBinding & {id: ID}
	adapters?: [ID=string]: #AdapterContract & {id: ID}
	evidenceRecords?: [ID=string]: #EvidenceRecord & {id: ID}
	hooks: [ID=string]: #HookBoundary & {id: ID}

	model: id: id

	for _, worker in workers {
		if worker.kind == "validation-worker" && worker.mayMutate {
			_validationWorkerMutationDenied: _|_
		}
	}

	_adapterWorkerRefs: {
		for _, adapter in adapters {
			"\(adapter.id)": workers[adapter.worker]
		}
	}

	_evidenceWorkerRefs: {
		for _, record in evidenceRecords {
			"\(record.id)": workers[record.workerID]
		}
	}

	_evidenceAdapterRefs: {
		for _, record in evidenceRecords {
			"\(record.id)": adapters[record.adapterID]
		}
	}

	_fixtureObligationAssertionRefs: {
		for _, obligation in fixtureObligations {
			"\(obligation.id)": assertions[obligation.assertion]
		}
	}

	_fixtureObligationTargetRefs: {
		for _, obligation in fixtureObligations {
			if obligation.targetPlanned == false {
				"\(obligation.id)": leaves[obligation.target]
			}
		}
	}

	_fixtureObligationWorkerRefs: {
		for _, obligation in fixtureObligations {
			if obligation.generation == "worker" {
				"\(obligation.id)": workers[obligation.worker]
			}
		}
	}

	_testObligationAssertionRefs: {
		for _, obligation in testObligations {
			"\(obligation.id)": assertions[obligation.assertion]
		}
	}

	_testObligationCheckRefs: {
		for _, obligation in testObligations {
			"\(obligation.id)": checks[obligation.check]
		}
	}

	_testObligationFixtureRefs: {
		for _, obligation in testObligations {
			for _, fixtureID in obligation.fixtures {
				"\(obligation.id).\(fixtureID)": fixtureObligations[fixtureID]
			}
		}
	}

	_coveredAssertions: {
		for _, item in coverage {
			if item.status != "deprecated" {
				"\(item.assertion)": true
			}
		}
	}

	for assertionID, assertion in assertions {
		if assertion.status == "active" && assertion.coverageExempt == false {
			_coveredAssertions: "\(assertionID)": true
		}
	}

	_coverageAssertionRefs: {
		for _, item in coverage {
			"\(item.id)": assertions[item.assertion]
		}
	}

	_coverageFixtureRefs: {
		for _, item in coverage {
			for _, fixtureID in item.requiredFixtures {
				"\(item.id).\(fixtureID)": fixtureObligations[fixtureID]
			}
		}
	}

	_coverageTestRefs: {
		for _, item in coverage {
			for _, testID in item.requiredTests {
				"\(item.id).\(testID)": testObligations[testID]
			}
		}
	}
})
