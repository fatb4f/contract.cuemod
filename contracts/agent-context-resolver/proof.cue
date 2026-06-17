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
	mergeReducer: {
		schema:        "agent.merge-reducer.v1"
		stage:         "merge_reduction"
		input:         "route_results"
		output:        "bounded_merge_packet"
		deterministic: true
		steps: [
			"schema_validation",
			"evidence_compression",
			"merge_policy",
			"bounded_merge_packet",
		]
		order: {
			primary:    "route.sequence"
			tieBreaker: "route.id"
			direction:  "ascending"
		}
		compression: {
			schema:                  "agent.evidence-compression.v1"
			stage:                   "evidence_compression"
			mode:                    "bounded"
			input:                   "validated_route_results"
			output:                  "compressed_evidence"
			mayReduceEvidenceVolume: true
			mustPreserveProvenance:  true
			provenanceFields: ["routeID", "evidence"]
			deny: {
				eraseProvenance:    true
				rawTranscriptInput: true
			}
		}
		policy: expectedMerge
		packet: {
			schema:                   "agent.bounded-merge-packet.v1"
			producer:                 "merge_reducer"
			stage:                    "bounded_merge_packet"
			deterministic:            true
			finalAuthority:           "root_codex"
			routeResultsAuthority:    "evidence_only"
			routeResultsAreAuthority: false
			maxSummaryTokens:         1200
			sourceRouteIDs: [
				routeInventory.routes[0].id,
				routeInventory.routes[1].id,
			]
			facts: []
			evidence: [
				{kind: "contract", ref: "contracts/agent-context-resolver/proof.cue"},
				{kind: "contract", ref: "contracts/agent-context-resolver/merge.cue"},
			]
			diagnostics: []
			conflicts: []
			deny: {
				rawWorkerTranscripts: true
				arbitraryTranscripts: true
				unboundedEvidence:    true
			}
		}
		deny: {
			rawWorkerTranscripts: true
			unstructuredResults:  true
			routeResultsAsFinal:  true
		}
	}
	modelSynthesisGate: {
		schema:  "agent.model-synthesis-gate.v1"
		stage:   "model_synthesis"
		allowed: false
		input:   routeCompilerProof.mergeReducer.packet
		reads:   "bounded_merge_packet_only"
		deny: {
			rawWorkerTranscripts:       true
			arbitraryRouteResultAccess: true
			routeResultsAsAuthority:    true
		}
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
		workerInvocations: [
			{
				schema:    "agent.route-worker-invocation.v1"
				routeID:   routeInventory.routes[0].id
				workerID:  "agent-context-resolver.validation-worker"
				profileID: "agent-context-resolver.a2a-worker"
				adapter:   "a2a"
				a2a: {
					runtime:                          "a2a"
					preferred:                        true
					offloadsContext:                  true
					offloadsRouteLocalResponsibility: true
					offloadsAuthority:                false
					rootAuthority:                    "root_codex"
					resultAuthority:                  "evidence_only"
					structuredResult:                 true
				}
				packet: {
					assignedBy: "root_codex"
					bounded:    true
					context:    routeCompilerProof.propagation.perRoute["resolver.inspect.current"]
				}
				returns: {
					schema:           routeInventory.routes[0].outputSchema
					evidenceRequired: true
					authority:        "evidence_only"
				}
				deny: {
					authorityDelegation:      true
					rawTranscriptForwarding:  true
					freeFormMCPToolExposure:  true
					sdkExecutionFromResolver: true
				}
			},
			{
				schema:    "agent.route-worker-invocation.v1"
				routeID:   routeInventory.routes[1].id
				workerID:  "agent-context-resolver.validation-worker"
				profileID: "agent-context-resolver.a2a-worker"
				adapter:   "a2a"
				a2a: {
					runtime:                          "a2a"
					preferred:                        true
					offloadsContext:                  true
					offloadsRouteLocalResponsibility: true
					offloadsAuthority:                false
					rootAuthority:                    "root_codex"
					resultAuthority:                  "evidence_only"
					structuredResult:                 true
				}
				packet: {
					assignedBy: "root_codex"
					bounded:    true
					context:    routeCompilerProof.propagation.perRoute["resolver.plan.compile"]
				}
				returns: {
					schema:           routeInventory.routes[1].outputSchema
					evidenceRequired: true
					authority:        "evidence_only"
				}
				deny: {
					authorityDelegation:      true
					rawTranscriptForwarding:  true
					freeFormMCPToolExposure:  true
					sdkExecutionFromResolver: true
				}
			},
		]
		requirements: {
			agentRuntimeRegistry:  "absent"
			workerAdapterRegistry: "absent"
			mcpRouteExecutor:      "absent"
		}
		execution: {
			allowed:                false
			preferredWorkerAdapter: "a2a"
			secondaryWorkerAdapters: ["sdk-direct", "mcp", "cli"]
			requiresA2AAdapter:      true
			requiresMCPAdapter:      false
			requiresRuntimeRegistry: true
			backend:                 "a2a"
		}
		deny: {
			directSDKSpawn:          true
			rawTranscriptForwarding: true
			rawRegistryDump:         true
			unselectedFragments:     true
			globalMutation:          true
			authorityDelegation:     true
			freeFormMCPToolExposure: true
		}
		expectedResult: {schema: "agent.route-result.v1"}
	}
}

routeEnvelopeProtocolProof: {
	schema: "agent.route-envelope-protocol-proof.v1"

	evidenceRecords: agentContextResolver.evidenceRecords
	checks: [
		for recordID, record in evidenceRecords {
			id:          recordID
			taskName:    record.routeEnvelope.taskName
			recipient:   record.routeEnvelope.recipient
			sender:      record.routeEnvelope.sender
			payloadID:   record.routeEnvelope.payload.id
			payloadKind: record.routeEnvelope.payload.kind

			metadata:       record.routeEnvelope.metadata
			sourceIdentity: record.routeEnvelope.sourceIdentity
			payloadBoundary: record.routeEnvelope.payloadBoundary & {
				encryptedContent: bool
			}

			authority:         record.routeEnvelope.authority & "correlation_only"
			definesGraphTruth: record.routeEnvelope.definesGraphTruth & false
			mutationAuthority: record.routeEnvelope.mutationAuthority & false

			if record.routeEnvelope.kind == "NEW_TASK" {
				payloadKind: "task"
			}
			if record.routeEnvelope.kind == "MESSAGE" {
				payloadKind: "message"
			}
			if record.routeEnvelope.kind == "FINAL_ANSWER" {
				payloadKind: "final_answer"
			}
		},
	]
}
