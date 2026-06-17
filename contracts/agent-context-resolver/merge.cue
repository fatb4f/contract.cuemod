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
	routeID: #DeclaredID
	status:  "pass" | "fail" | "blocked" | "partial"
	summary: string & !=""
	facts?: [...string & !=""]
	evidence?: [...#EvidenceRef]
	touchedPaths?: [...string & !=""]
	diagnostics?: [...string & !=""]
	patchPlan?: [...#PatchOp]
	tokenCost?: int & >=0
	authority:  "evidence_only"
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
