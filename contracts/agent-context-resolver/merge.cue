package agentcontextresolver

#EvidenceRef: close({
	kind: "file" | "command" | "artifact" | "contract"
	ref:  string & !=""
})

#PatchOp: close({
	op:   "add" | "update" | "delete"
	path: string & !=""
})

#RouteResult: close({
	routeID:    #DeclaredID
	workerID?:  #DeclaredID
	profileID?: #DeclaredID
	adapter?:   #WorkerRuntimeAdapter
	status:     "pass" | "fail" | "blocked" | "partial"
	summary:    string & !=""
	facts?: [...string & !=""]
	evidence?: [...#EvidenceRef]
	responseItemMetadata?: #ResponseItemMetadata
	sourceIdentity?:       #ResponseItemSourceIdentity
	routeEnvelope?:        #MultiAgentV2RouteEnvelope
	touchedPaths?: [...string & !=""]
	diagnostics?: [...string & !=""]
	patchPlan?: [...#PatchOp]
	tokenCost?: int & >=0
	authority:  "evidence_only"
})

#EvidenceRecord: close({
	schema: "agent.evidence-record.v1"
	id:     #DeclaredID
	kind:   "route-worker-evidence"

	routeID:               #DeclaredID
	workerID:              #DeclaredID
	profileID:             #DeclaredID
	adapterID:             #DeclaredID
	invocationID:          #DeclaredID
	adapterExecutionID:    #DeclaredID
	routeResultID:         #DeclaredID
	adapter:               #WorkerRuntimeAdapter
	responseItemMetadata?: #ResponseItemMetadata
	sourceIdentity:        #ResponseItemSourceIdentity
	routeEnvelope: #MultiAgentV2RouteEnvelope & {
		routeID:        routeID
		workerID:       workerID
		adapterID:      adapterID
		metadata?:      responseItemMetadata
		sourceIdentity: sourceIdentity
	}
	payloadBoundary: #PayloadBoundary

	status:  "pass" | "fail" | "blocked" | "partial"
	summary: string & !=""
	observedEvidence: [...#EvidenceRef]
	diagnostics?: [...string & !=""]

	reportsObservedResults: true
	checksExpectedEvidence: bool | *true
	authority:              "evidence_only"
	definesGraphTruth:      false
	mutationAuthority:      false
	description?:           string & !=""
})

#RouteResultEvidenceMapping: close({
	schema: "agent.route-result-evidence-mapping.v1"

	invocation:       #RouteWorkerInvocation
	adapterContract:  #AdapterContract
	adapterExecution: #AdapterExecution
	routeResult:      #RouteResult
	evidenceRecord:   #EvidenceRecord

	adapterContract: {
		id:              evidenceRecord.adapterID
		workerBindingID: invocation.workerID
		workerProfileID: invocation.profileID
	}
	adapterExecution: {
		adapterID:    adapterContract.id
		invocationID: evidenceRecord.invocationID
		routeID:      invocation.routeID
		workerID:     invocation.workerID
	}
	routeResult: {
		routeID:               invocation.routeID
		workerID:              invocation.workerID
		profileID:             invocation.profileID
		adapter:               invocation.adapter
		status:                evidenceRecord.status
		summary:               evidenceRecord.summary
		responseItemMetadata?: evidenceRecord.responseItemMetadata
		sourceIdentity:        evidenceRecord.sourceIdentity
		routeEnvelope:         evidenceRecord.routeEnvelope
		authority:             "evidence_only"
	}
	evidenceRecord: {
		routeID:            invocation.routeID
		workerID:           invocation.workerID
		profileID:          invocation.profileID
		adapterID:          adapterContract.id
		invocationID:       adapterExecution.invocationID
		adapterExecutionID: adapterExecution.id
		adapter:            invocation.adapter
		status:             routeResult.status
		summary:            routeResult.summary
		sourceIdentity:     routeResult.sourceIdentity
		routeEnvelope:      routeResult.routeEnvelope
		authority:          "evidence_only"
		definesGraphTruth:  false
		mutationAuthority:  false
	}
})

#RouteResultSchema: close({
	schema: "agent.route-result.v1"
	result: #RouteResult
})

#MergePolicy: close({
	mode:                     "ordered" | "evidence_weighted" | "fail_closed"
	requireStructuredResults: bool | *true
	requireEvidenceForClaims: bool | *true
	conflictPolicy:           "block" | "prefer_higher_priority" | "root_decides"
	maxMergedSummaryTokens?:  int & >0
	finalAuthority:           "root_codex"
	routeResultsAreAuthority: false
})

#EvidenceCompression: close({
	schema: "agent.evidence-compression.v1"
	stage:  "evidence_compression"
	mode:   "none" | *"bounded"

	input:  "validated_route_results"
	output: "compressed_evidence"

	mayReduceEvidenceVolume: bool | *true
	mustPreserveProvenance:  true
	provenanceFields: [...string & !=""] | *["routeID", "evidence"]

	deny: close({
		eraseProvenance:    true
		rawTranscriptInput: true
	})

	if mode == "none" {
		mayReduceEvidenceVolume: false
	}
})

#BoundedMergePacket: close({
	schema:   "agent.bounded-merge-packet.v1"
	producer: "merge_reducer"
	stage:    "bounded_merge_packet"

	deterministic:            true
	finalAuthority:           "root_codex"
	routeResultsAuthority:    "evidence_only"
	routeResultsAreAuthority: false

	maxSummaryTokens: int & >0
	sourceRouteIDs: [...#DeclaredID]
	facts?: [...string & !=""]
	evidence: [...#EvidenceRef]
	diagnostics?: [...string & !=""]
	conflicts?: [...close({
		routeIDs: [...#DeclaredID] & [_, ...]
		summary:    string & !=""
		resolution: "blocked" | "root_decides"
	})]

	deny: close({
		rawWorkerTranscripts: true
		arbitraryTranscripts: true
		unboundedEvidence:    true
	})
})

#MergeReducer: close({
	schema: "agent.merge-reducer.v1"
	stage:  "merge_reduction"

	input:  "route_results"
	output: "bounded_merge_packet"

	deterministic: true
	steps: [
		"schema_validation",
		"evidence_compression",
		"merge_policy",
		"bounded_merge_packet",
	]
	order: close({
		primary:    "route.sequence"
		tieBreaker: "route.id"
		direction:  "ascending"
	})

	compression: #EvidenceCompression
	policy: #MergePolicy & {
		requireStructuredResults: true
		requireEvidenceForClaims: true
		finalAuthority:           "root_codex"
		routeResultsAreAuthority: false
	}
	packet: #BoundedMergePacket

	deny: close({
		rawWorkerTranscripts: true
		unstructuredResults:  true
		routeResultsAsFinal:  true
	})
})

#ModelSynthesisGate: close({
	schema: "agent.model-synthesis-gate.v1"
	stage:  "model_synthesis"

	allowed: bool | *false
	input: #BoundedMergePacket & {
		producer:      "merge_reducer"
		deterministic: true
	}
	reads: "bounded_merge_packet_only"

	deny: close({
		rawWorkerTranscripts:       true
		arbitraryRouteResultAccess: true
		routeResultsAsAuthority:    true
	})
})
