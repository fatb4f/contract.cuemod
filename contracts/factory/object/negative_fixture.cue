package object

#RuntimeEvent: close({
	id:      #RuntimeEventID
	schema:  "factory.runtime-event.v1"
	source:  "agent-runtime" | "agent-context-resolver" | "worker"
	summary: #BoundedSummary
})

#ResolverSelection: close({
	id:     #ResolverSelectionID
	schema: "factory.resolver-selection.v1"
	source: "agent-context-resolver"
	selected: [...#ObjectID] & [_, ...]
	reason: #BoundedSummary
})

#WorkerSelection: close({
	id:       #ObjectID
	schema:   "factory.worker-selection.v1"
	workerID: #WorkerID
	kind:     #WorkerKind
	reason:   #BoundedSummary
})

#EvidenceRequest: close({
	id:     #EvidenceRequestID
	schema: "factory.evidence-request.v1"
	worker: #WorkerSelection
	fixtures: [...#NegativeFixtureID] & [_, ...]
	question: #BoundedSummary
})

#NegativeFixture: close({
	id:      #NegativeFixtureID
	schema:  "factory.negative-fixture.v1"
	surface: #TransitionSurface
	fails:   #BoundedSummary
	mustNotExpose?: [...#RawObservationKind]
})
