package agentcontextresolver

#ProofCheck: {
	id:   string
	pass: true
}

#LifecycleReport: {
	version: "contract-cuemod.agent-context-resolver-proof/v1"
	checks: [...#ProofCheck] & [_, ...]
}

routeCompilerProof: #ResolvedRoutePlan & {
	schema:               "agent.route-plan.v1"
	turnID:               "proof-turn"
	intent:               "resolver"
	availableFragmentIDs: _availableFragmentIDs
	availableRouteIDs:    _registeredRouteIDs
	selectedFragments: ["agent-context-resolver.authority"]
	routes: [
		{
			id:             routeInventory.routes[0].id
			kind:           routeInventory.routes[0].kind
			priority:       routeInventory.routes[0].priority
			sequence:       routeInventory.routes[0].sequence
			parallelGroup:  routeInventory.routes[0].parallelGroup
			dependsOn:      routeInventory.routes[0].dependsOn
			inputFragments: routeInventory.routes[0].inputFragments
			task:           routeInventory.routes[0].task
			outputSchema:   routeInventory.routes[0].outputSchema
			gates:          routeInventory.routes[0].gates
		},
		{
			id:             routeInventory.routes[1].id
			kind:           routeInventory.routes[1].kind
			priority:       routeInventory.routes[1].priority
			sequence:       routeInventory.routes[1].sequence
			dependsOn:      routeInventory.routes[1].dependsOn
			inputFragments: routeInventory.routes[1].inputFragments
			task:           routeInventory.routes[1].task
			outputSchema:   routeInventory.routes[1].outputSchema
			gates:          routeInventory.routes[1].gates
		},
	]
	propagation: {
		mode: "route-local"
		root: {
			includes: {
				intent: "resolver"
				selectedFragments: ["agent-context-resolver.authority"]
				acceptedRouteResults: []
			}
			excludes: ["raw route logs", "unvalidated route claims", "runtime implementation details"]
		}
		perRoute: {
			"resolver.inspect.current": {
				includes: {
					objective: routeInventory.routes[0].task.objective
					acceptedFacts: []
					selectedFragments: routeInventory.routes[0].inputFragments
					files: ["contracts/agent-context-resolver"]
				}
				excludes: ["full transcript", "unselected fragments", "raw registry", "unbounded tool logs", "irrelevant route outputs"]
				return: {
					schema:           routeInventory.routes[0].outputSchema
					maxSummaryTokens: 800
					evidenceRequired: true
				}
			}
			"resolver.plan.compile": {
				includes: {
					objective: routeInventory.routes[1].task.objective
					acceptedFacts: []
					selectedFragments: routeInventory.routes[1].inputFragments
					files: ["contracts/agent-context-resolver"]
					priorArtifacts: ["resolver.inspect.current"]
				}
				excludes: ["full transcript", "unselected fragments", "raw registry", "unbounded tool logs", "irrelevant route outputs"]
				return: {
					schema:           routeInventory.routes[1].outputSchema
					maxSummaryTokens: 800
					evidenceRequired: true
				}
			}
		}
		denyFullTranscript:      true
		denyRawRegistryDump:     true
		denyUnselectedFragments: true
		requireStructuredResult: true
	}
	gates: gateInventory
	expectedMerge: {
		mode:                     "fail_closed"
		requireStructuredResults: true
		requireEvidenceForClaims: true
		conflictPolicy:           "root_decides"
		maxMergedSummaryTokens:   1200
		finalAuthority:           "root_codex"
		routeResultsAreAuthority: false
	}
	runtime: {
		mode: "requires-agent-runtime"
		routeRefs: [
			{
				schema:       "agent.runtime-route-reference.v1"
				routeID:      routeInventory.routes[0].id
				routeKind:    routeInventory.routes[0].kind
				context:      routeCompilerProof.propagation.perRoute["resolver.inspect.current"]
				outputSchema: routeInventory.routes[0].outputSchema
			},
			{
				schema:       "agent.runtime-route-reference.v1"
				routeID:      routeInventory.routes[1].id
				routeKind:    routeInventory.routes[1].kind
				context:      routeCompilerProof.propagation.perRoute["resolver.plan.compile"]
				outputSchema: routeInventory.routes[1].outputSchema
			},
		]
		requirements: {
			agentRuntimeRegistry: "absent"
			mcpRouteExecutor:     "absent"
		}
		execution: {
			allowed:                 false
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
}
