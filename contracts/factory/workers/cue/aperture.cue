package cueworker

import workers "github.com/fatb4f/contract.reflective-transition-factory/contracts/factory/workers"

#CueWorkerAperture: workers.#WorkerAperture & {
	worker: {
		kind: "cue"
	}
	method:
		"inspectGraph" |
		"listObjects" |
		"detectNegativeFixtures" |
		"evaluateCandidate" |
		"validateAssertions" |
		"exportTransition" |
		"projectPatch"
	excludes: [
		"raw-cue-output",
		"full-repo-firehose",
	]
}
