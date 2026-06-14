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
