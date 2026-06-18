package cuelsp

import cueworker "github.com/fatb4f/contract.reflective-transition-factory/contracts/factory/workers/cue:cueworker"

apertureReference: cueworker.#CueWorkerAperture & {
	worker: {
		id:       "factory.worker/cue-lsp"
		workerID: "cue-lsp"
		reason:   "bounded CUE graph inspection through language-server evidence"
	}
	method: "inspectGraph"
	outputs: [{
		id:        "factory.evidence/cue-lsp"
		schema:    "factory.evidence.v1"
		requestID: "factory.request/cue-lsp"
		workerID:  "cue-lsp"
		kind:      "inspection"
		summary:   "CUE definition, reference, symbol, diagnostic, and validation evidence"
		bounds: {
			excludes: excludes
		}
	}]
}

semanticOwnership: [
	"contract-definitions",
	"references",
	"constraints",
	"diagnostics",
	"schema-completeness",
]
