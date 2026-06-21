package invalidmaterializationbeforeadmittedtransition

import object "github.com/fatb4f/contract.reflective-transition-factory/contracts/factory/object"

unadmittedCandidate: object.#Candidate & {
	id:      "candidate/unadmitted-materialization"
	schema:  "factory.candidate.v1"
	fixtures: ["fixture/raw-authority-blocked"]
	evidence: ["evidence/bounded-worker-summary"]
	intent:   "This candidate is not admitted."
	transitionSurface: "material"
}

unadmittedVerdict: object.#FixtureVerdict & {
	schema:    "factory.fixture-verdict.v1"
	fixtureID: "fixture/raw-authority-blocked"
	verdict:   "negated"
	evidence: ["evidence/bounded-worker-summary"]
	reason: "Fixture is negated."
}

unadmittedEvaluation: object.#Evaluation & {
	id:         "evaluation/unadmitted-materialization"
	schema:     "factory.evaluation.v1"
	candidate:  unadmittedCandidate
	verdicts:   [unadmittedVerdict]
	assertions: []
	passed:     true
}

unadmittedFeedback: object.#Feedback & {
	id:         "feedback/unadmitted-materialization"
	schema:     "factory.feedback.v1"
	evaluation: unadmittedEvaluation
	decision:   "admit"
	reason:     "Feedback admits, but the transition is contradicted below."
}

unadmittedTransition: object.#Transition & {
	id:       "transition/not-admitted"
	schema:   "factory.transition.v1"
	feedback: unadmittedFeedback
	admitted: false
	binds: semantic: unadmittedCandidate.id
}

invalidMaterialization: object.#Materialization & {
	id:         "materialization/before-admission"
	schema:     "factory.materialization.v1"
	transition: unadmittedTransition
	workerID:   "worker/cue-gate"
	surface:    "material"
	summary:    "This materialization must not exist before admission."
}
