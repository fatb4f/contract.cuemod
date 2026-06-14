package invalidworkerresultmismatch

import (
	runtime "github.com/fatb4f/contract.cuemod/contracts/agent-runtime:agentruntime"
	fixtures "github.com/fatb4f/contract.cuemod/fixtures/agent-runtime:agentruntime"
)

invalid: runtime.#WorkerResult & fixtures.validWorkerResult & {
	worker: "fixture-worker"
}
