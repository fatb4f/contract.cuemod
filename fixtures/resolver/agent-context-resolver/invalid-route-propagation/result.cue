package invalidroutepropagation

import fixtures "github.com/fatb4f/contract.cuemod/fixtures/resolver/agent-context-resolver:agentcontextresolver"

invalid: fixtures.#FixturePlan & {
	propagation: perRoute: "resolver.inspect.current": includes: {
		fullTranscript:  true
		rawRegistryDump: true
		unselectedFragments: ["fragment.unknown"]
	}
}
