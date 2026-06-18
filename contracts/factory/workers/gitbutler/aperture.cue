package gitbutlerworker

import workers "github.com/fatb4f/contract.reflective-transition-factory/contracts/factory/workers"

#GitButlerWorkerAperture: workers.#WorkerAperture & {
	worker: {
		kind: "gitbutler"
	}
	method:
		"inspectWorkspace" |
		"listStacks" |
		"listAssignments" |
		"detectConflicts" |
		"proposeTransition" |
		"evaluateTransition" |
		"materializeTransition"
	excludes: [
		"raw-diff",
		"raw-log",
		"raw-git-topology",
		"full-repo-firehose",
	]
}
