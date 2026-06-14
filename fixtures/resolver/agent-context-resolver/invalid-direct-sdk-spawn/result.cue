package invaliddirectsdkspawn

import fixtures "github.com/fatb4f/contract.cuemod/fixtures/resolver/agent-context-resolver:agentcontextresolver"

invalid: fixtures.#FixturePlan & {
	runtime: deny: directSDKSpawn: false
}
