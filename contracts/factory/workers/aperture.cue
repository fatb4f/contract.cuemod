package workers

import object "github.com/fatb4f/contract.reflective-transition-factory/contracts/factory/object"

#WorkerMethod:
	"inspectGraph" |
	"listObjects" |
	"detectNegativeFixtures" |
	"evaluateCandidate" |
	"validateAssertions" |
	"exportTransition" |
	"projectPatch" |
	"inspectRuntime" |
	"inspectContextWindow" |
	"inspectQuota" |
	"proposeContextPacket" |
	"evaluateHandoff" |
	"materializeRuntimeAction" |
	"inspectWorkspace" |
	"listStacks" |
	"listAssignments" |
	"detectConflicts" |
	"proposeTransition" |
	"evaluateTransition" |
	"materializeTransition"

#WorkerAperture: close({
	worker:   object.#WorkerSelection
	method:   #WorkerMethod
	request?: object.#EvidenceRequest
	inputs?: [...object.#ObjectID]
	outputs: [...#WorkerOutput] & [_, ...]
	excludes: [...object.#RawObservationKind] & [_, ...]
})

#WorkerOutput:
	object.#Evidence |
	object.#WorkerReflection |
	object.#Evaluation |
	object.#Candidate |
	object.#Feedback |
	object.#Transition |
	object.#Materialization

#CueWorkerMethods: [
	"inspectGraph",
	"listObjects",
	"detectNegativeFixtures",
	"evaluateCandidate",
	"validateAssertions",
	"exportTransition",
	"projectPatch",
]

#CodexWorkerMethods: [
	"inspectRuntime",
	"inspectContextWindow",
	"inspectQuota",
	"proposeContextPacket",
	"evaluateHandoff",
	"materializeRuntimeAction",
]

#GitButlerWorkerMethods: [
	"inspectWorkspace",
	"listStacks",
	"listAssignments",
	"detectConflicts",
	"proposeTransition",
	"evaluateTransition",
	"materializeTransition",
]
