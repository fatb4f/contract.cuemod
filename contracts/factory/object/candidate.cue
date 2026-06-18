package object

#WorkerReflection: close({
	id:       #ObjectID
	schema:   "factory.worker-reflection.v1"
	workerID: #WorkerID
	kind:     #WorkerKind
	summary:  #BoundedSummary
	evidence: [...#EvidenceID]
})

#Evidence: close({
	id:        #EvidenceID
	schema:    "factory.evidence.v1"
	requestID: #EvidenceRequestID
	workerID:  #WorkerID
	kind:      "inspection" | "evaluation" | "projection" | "reflection"
	summary:   #BoundedSummary
	bounds: close({
		excludes: [...#RawObservationKind] & [_, ...]
	})
})

#Candidate: close({
	id:     #CandidateID
	schema: "factory.candidate.v1"
	fixtures: [...#NegativeFixtureID] & [_, ...]
	evidence: [...#EvidenceID] & [_, ...]
	intent:            #BoundedSummary
	transitionSurface: #TransitionSurface
})
