package invalidfeedbackadmitsfailedevaluation

import object "github.com/fatb4f/contract.reflective-transition-factory/contracts/factory/object"

failedCandidate: object.#Candidate & {
	id:      "candidate/failed-evaluation"
	schema:  "factory.candidate.v1"
	fixtures: ["fixture/raw-authority-blocked"]
	evidence: ["evidence/bounded-worker-summary"]
	intent:   "This candidate failed fixture evaluation."
	transitionSurface: "semantic"
}

failedVerdict: object.#FixtureVerdict & {
	schema:    "factory.fixture-verdict.v1"
	fixtureID: "fixture/raw-authority-blocked"
	verdict:   "still-fails"
	evidence: ["evidence/bounded-worker-summary"]
	reason: "Raw authority exposure remains."
}

failedEvaluation: object.#Evaluation & {
	id:         "evaluation/failed"
	schema:     "factory.evaluation.v1"
	candidate:  failedCandidate
	verdicts:   [failedVerdict]
	assertions: []
	passed:     false
}

invalidFeedback: object.#Feedback & {
	id:         "feedback/invalid-admit"
	schema:     "factory.feedback.v1"
	evaluation: failedEvaluation
	decision:   "admit"
	reason:     "This feedback must not admit a failed evaluation."
}
