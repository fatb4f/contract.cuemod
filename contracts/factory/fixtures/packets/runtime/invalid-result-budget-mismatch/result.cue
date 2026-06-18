package invalidresultbudgetmismatch

import (
	runtime "github.com/fatb4f/contract.cuemod/contracts/agent-runtime:agentruntime"
	fixtures "github.com/fatb4f/contract.cuemod/fixtures/agent-runtime:agentruntime"
)

invalid: runtime.#RuntimeResult & fixtures.validResult & {
	budget: id: "validate-standard"
}
