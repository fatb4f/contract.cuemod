package cuerg

import cueworker "github.com/fatb4f/contract.reflective-transition-factory/contracts/factory/workers/cue:cueworker"

apertureReference: cueworker.#CueWorkerAperture & {
	worker: {
		id:       "factory.worker/cue-rg"
		workerID: "cue-rg"
		reason:   "bounded text evidence for CUE projection and fixture inspection"
	}
	method: "listObjects"
	outputs: [{
		id:        "factory.evidence/cue-rg"
		schema:    "factory.evidence.v1"
		requestID: "factory.request/cue-rg"
		workerID:  "cue-rg"
		kind:      "inspection"
		summary:   "Range-bounded textual evidence from CUE packages and generated projections"
		bounds: {
			excludes: excludes
		}
	}]
}

semanticOwnership: [
	"projected-artifact-text",
	"range-evidence",
]
