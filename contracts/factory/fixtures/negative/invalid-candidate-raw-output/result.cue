package invalidcandidaterawoutput

import object "github.com/fatb4f/contract.reflective-transition-factory/contracts/factory/object"

candidate: object.#Candidate & {
	id:      "candidate/raw-output"
	schema:  "factory.candidate.v1"
	fixtures: ["fixture/raw-authority-blocked"]
	evidence: ["evidence/raw-output"]
	intent:   "This candidate attempts to expose raw authority output."
	transitionSurface: "semantic"
	rawDiff: "diff --git a/contracts/factory/object/candidate.cue b/contracts/factory/object/candidate.cue"
	rawLog: "unbounded worker log"
	sdkOutput: "raw SDK internals"
	cueOutput: "raw CUE output"
}
