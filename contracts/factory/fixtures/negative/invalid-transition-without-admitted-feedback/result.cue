package invalidtransitionwithoutadmittedfeedback

import object "github.com/fatb4f/contract.reflective-transition-factory/contracts/factory/object"

rejectedCandidate: object.#Candidate & {
	id:      "candidate/rejected-feedback"
	schema:  "factory.candidate.v1"
	fixtures: ["fixture/raw-authority-blocked"]
	evidence: ["evidence/bounded-worker-summary"]
	intent:   "This candidate is rejected by feedback."
	transitionSurface: "semantic"
}

rejectedVerdict: object.#FixtureVerdict & {
	schema:    "factory.fixture-verdict.v1"
	fixtureID: "fixture/raw-authority-blocked"
	verdict:   "negated"
	evidence: ["evidence/bounded-worker-summary"]
	reason: "Fixture is negated."
}

rejectedEvaluation: object.#Evaluation & {
	id:         "evaluation/rejected-feedback"
	schema:     "factory.evaluation.v1"
	candidate:  rejectedCandidate
	verdicts:   [rejectedVerdict]
	assertions: []
	passed:     true
}

rejectedFeedback: object.#Feedback & {
	id:         "feedback/reject"
	schema:     "factory.feedback.v1"
	evaluation: rejectedEvaluation
	decision:   "reject"
	reason:     "This feedback does not admit the transition."
}

invalidTransition: object.#Transition & {
	id:       "transition/without-admit"
	schema:   "factory.transition.v1"
	feedback: rejectedFeedback
	admitted: true
	binds: semantic: rejectedCandidate.id
}
