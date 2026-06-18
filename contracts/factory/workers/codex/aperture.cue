package codexworker

import workers "github.com/fatb4f/contract.reflective-transition-factory/contracts/factory/workers"

#CodexWorkerAperture: workers.#WorkerAperture & {
	worker: {
		kind: "codex"
	}
	method:
		"inspectRuntime" |
		"inspectContextWindow" |
		"inspectQuota" |
		"proposeContextPacket" |
		"evaluateHandoff" |
		"materializeRuntimeAction"
	excludes: [
		"raw-sdk-internals",
		"raw-codex-runtime-internals",
		"full-repo-firehose",
	]
}
