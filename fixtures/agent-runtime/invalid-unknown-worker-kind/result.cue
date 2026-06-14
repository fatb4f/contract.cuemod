package invalidunknownworkerkind

import fixtures "github.com/fatb4f/contract.cuemod/fixtures/agent-runtime:agentruntime"

invalid: fixtures.#ValidWorkerRequest & {
	worker: "unknown-worker"
}
