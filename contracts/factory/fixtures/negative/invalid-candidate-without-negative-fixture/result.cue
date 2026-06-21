package invalidcandidatewithoutnegativefixture

import object "github.com/fatb4f/contract.reflective-transition-factory/contracts/factory/object"

candidate: object.#Candidate & {
	id:      "candidate/missing-negative-fixture"
	schema:  "factory.candidate.v1"
	fixtures: []
	evidence: ["evidence/bounded-worker-summary"]
	intent:   "This candidate has no negative fixture gate."
	transitionSurface: "semantic"
}
