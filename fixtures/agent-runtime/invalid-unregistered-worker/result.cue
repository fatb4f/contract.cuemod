package invalidunregisteredworker

import (
	runtime "github.com/fatb4f/contract.cuemod/contracts/agent-runtime:agentruntime"
	fixtures "github.com/fatb4f/contract.cuemod/fixtures/agent-runtime:agentruntime"
)

invalid: runtime.#RuntimeInvocation & fixtures.fixtureInvocationInput & {
	workerID: "worker.unregistered"
	budgetID: "inspect-standard"
}
