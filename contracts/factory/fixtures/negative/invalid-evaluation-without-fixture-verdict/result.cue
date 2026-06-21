package invalidevaluationwithoutfixtureverdict

import object "github.com/fatb4f/contract.reflective-transition-factory/contracts/factory/object"

fixtureCandidate: object.#Candidate & {
	id:      "candidate/missing-verdict"
	schema:  "factory.candidate.v1"
	fixtures: ["fixture/raw-authority-blocked"]
	evidence: ["evidence/bounded-worker-summary"]
	intent:   "This candidate has no matching fixture verdict."
	transitionSurface: "semantic"
}

missingVerdictEvaluation: object.#Evaluation & {
	id:         "evaluation/missing-verdict"
	schema:     "factory.evaluation.v1"
	candidate:  fixtureCandidate
	verdicts:   []
	assertions: []
	passed:     true
}
