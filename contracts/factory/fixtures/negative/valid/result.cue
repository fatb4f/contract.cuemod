package valid

import object "github.com/fatb4f/contract.reflective-transition-factory/contracts/factory/object"

negativeFixture: object.#NegativeFixture & {
	id:      "fixture/raw-authority-blocked"
	schema:  "factory.negative-fixture.v1"
	surface: "semantic"
	fails:   "A candidate must not expose raw authority output as proof."
	mustNotExpose: [
		"raw-diff",
		"raw-log",
		"raw-sdk-internals",
		"raw-cue-output",
	]
}

evidence: object.#Evidence & {
	id:        "evidence/bounded-worker-summary"
	schema:    "factory.evidence.v1"
	requestID: "request/raw-authority-blocked"
	workerID:  "worker/cue-gate"
	kind:      "evaluation"
	summary:   "Worker returned bounded evidence and excluded raw authority output."
	bounds: excludes: [
		"raw-diff",
		"raw-log",
		"raw-sdk-internals",
		"raw-cue-output",
	]
}

gateCandidate: object.#Candidate & {
	id:      "candidate/negative-fixture-gate"
	schema:  "factory.candidate.v1"
	fixtures: ["fixture/raw-authority-blocked"]
	evidence: ["evidence/bounded-worker-summary"]
	intent:   "Admit only bounded factory transition evidence."
	transitionSurface: "semantic"
}

gateVerdict: object.#FixtureVerdict & {
	schema:    "factory.fixture-verdict.v1"
	fixtureID: "fixture/raw-authority-blocked"
	verdict:   "negated"
	evidence: ["evidence/bounded-worker-summary"]
	reason: "Candidate evidence negates the raw authority exposure fixture."
}

gateAssertion: object.#AssertionResult & {
	id:      "assertion/negative-fixture-negated"
	schema:  "factory.assertion-result.v1"
	name:    "negative_fixture_negated"
	passed:  true
	subject: gateCandidate.id
	reason:  "All candidate fixtures have passing verdicts."
}

gateEvaluation: object.#Evaluation & {
	id:         "evaluation/negative-fixture-gate"
	schema:     "factory.evaluation.v1"
	candidate:  gateCandidate
	verdicts:   [gateVerdict]
	assertions: [gateAssertion]
	passed:     true
}

gateFeedback: object.#Feedback & {
	id:         "feedback/negative-fixture-gate"
	schema:     "factory.feedback.v1"
	evaluation: gateEvaluation
	decision:   "admit"
	reason:     "Evaluation passed with a negated negative fixture."
}

gateTransition: object.#Transition & {
	id:       "transition/negative-fixture-gate"
	schema:   "factory.transition.v1"
	feedback: gateFeedback
	admitted: true
	binds: semantic: gateCandidate.id
}

gateMaterialization: object.#Materialization & {
	id:         "materialization/negative-fixture-gate"
	schema:     "factory.materialization.v1"
	transition: gateTransition
	workerID:   "worker/cue-gate"
	surface:    "semantic"
	summary:    "Materialization follows an admitted factory transition."
}
