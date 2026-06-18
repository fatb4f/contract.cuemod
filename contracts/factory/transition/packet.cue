package transition

import object "github.com/fatb4f/contract.reflective-transition-factory/contracts/factory/object"

#TransitionPacket: close({
	schema: "factory.transition-packet.v1"
	runtimeEvents: [...object.#RuntimeEvent]
	resolverSelections: [...object.#ResolverSelection]
	workerSelections: [...object.#WorkerSelection]
	evidenceRequests: [...object.#EvidenceRequest]
	reflections: [...object.#WorkerReflection]
	evidence: [...object.#Evidence]
	negativeFixtures: [...object.#NegativeFixture] & [_, ...]
	candidates: [...object.#Candidate]
	evaluations: [...object.#Evaluation]
	feedback: [...object.#Feedback]
	transitions: [...object.#Transition]
	materializations: [...object.#Materialization]
})
