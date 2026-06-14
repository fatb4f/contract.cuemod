package invalidruntimeroutedrift

import (
	resolver "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver:agentcontextresolver"
	runtime "github.com/fatb4f/contract.cuemod/contracts/agent-runtime:agentruntime"
	fixtures "github.com/fatb4f/contract.cuemod/fixtures/agent-runtime:agentruntime"
)

invalid: runtime.#ResolverRuntimeHandoff & {
	runtimeProjection: {
		mode: "eligible"
		routeRefs: [resolver.#RuntimeRouteReference & {
			schema:    "agent.runtime-route-reference.v1"
			routeID:   "resolver.route.drift"
			routeKind: "inspect"
			context:   fixtures.#FixtureContext
			outputSchema: {schema: "agent.route-result.inspect.v1"}
		}]
		requirements: {
			agentRuntimeRegistry: "present"
			mcpRouteExecutor:     "present"
		}
		execution: {
			allowed:                 true
			requiresMCPAdapter:      true
			requiresRuntimeRegistry: true
			backend:                 "codex-sdk"
		}
		deny: {
			directSDKSpawn:          true
			rawTranscriptForwarding: true
			rawRegistryDump:         true
			unselectedFragments:     true
			globalMutation:          true
		}
		expectedResult: {schema: "agent.route-result.v1"}
	}
	invocation: {}
	result: {}
}
