package agentcontextresolver

#WorkerRuntimeAdapter:
	"a2a" |
	"sdk-direct" |
	"mcp" |
	"cli"

#ResponseItemMetadata: close({
	turn_id?: string & !=""
})

#ResponseItemSourceIdentity: close({
	sourceKind:      "response_item" | "route_worker" | "adapter_execution"
	sourceID:        #DeclaredID
	producerID?:     #DeclaredID
	responseItemID?: string & !=""
})

#MultiAgentV2EnvelopeKind:
	"NEW_TASK" |
	"MESSAGE" |
	"FINAL_ANSWER"

#AgentPath: string & =~"^/[A-Za-z0-9._/-]+$"

#A2APayloadKind:
	"task" |
	"message" |
	"final_answer" |
	"route_result" |
	"evidence"

#A2APayloadRef: close({
	id:   #DeclaredID
	kind: #A2APayloadKind
})

#PayloadBoundary: close({
	plaintextEnvelope: true
	encryptedContent:  bool

	plaintextCarriesCorrelationOnly: true
	encryptedContentOpaque:          true
	definesGraphTruth:               false
	mutationAuthority:               false
})

#MultiAgentV2RouteEnvelope: close({
	schema: "codex.multi-agent.route-envelope.v2"
	kind:   #MultiAgentV2EnvelopeKind

	routeID:         #DeclaredID
	workerID?:       #DeclaredID
	adapterID?:      #DeclaredID
	metadata?:       #ResponseItemMetadata
	sourceIdentity:  #ResponseItemSourceIdentity
	taskName:        #AgentPath
	recipient:       #AgentPath
	sender:          #AgentPath
	payload:         #A2APayloadRef
	payloadBoundary: #PayloadBoundary

	authority:         "correlation_only"
	definesGraphTruth: false
	mutationAuthority: false

	if kind == "NEW_TASK" {
		payload: {
			kind: "task"
		}
	}

	if kind == "MESSAGE" {
		payload: {
			kind: "message"
		}
	}

	if kind == "FINAL_ANSWER" {
		payload: {
			kind: "final_answer"
		}
	}
})

#A2AWorkerAdapter: close({
	runtime:   "a2a"
	preferred: true

	offloadsContext:                  true
	offloadsRouteLocalResponsibility: true
	offloadsAuthority:                false

	rootAuthority:    "root_codex"
	resultAuthority:  "evidence_only"
	structuredResult: true
})

#WorkerProfile: close({
	id: #DeclaredID

	runtime:          #WorkerRuntimeAdapter | *"a2a"
	preferredRuntime: "a2a" | *"a2a"
	secondaryAdapters: [...#WorkerRuntimeAdapter] | *["sdk-direct", "mcp", "cli"]

	a2a: #A2AWorkerAdapter & {
		runtime:   "a2a"
		preferred: true
	}

	controlInvariants: [...string & !=""] | *[
		"Workers are predefined adapter-backed capabilities.",
		"Root Codex assigns bounded invocation packets.",
		"Workers return structured evidence.",
		"A2A offloads context and route-local responsibility.",
		"A2A does not offload authority.",
	]

	if runtime == "a2a" {
		preferredRuntime: "a2a"
	}
})

#WorkerBinding: close({
	id: #DeclaredID

	profileID:      #DeclaredID
	runtimeAdapter: #WorkerRuntimeAdapter | *"a2a"

	routeIDs: [...#DeclaredID] & [_, ...]

	bounded:                true
	resultAuthority:        "evidence_only"
	structuredResultSchema: #RouteOutputSchema

	deny: close({
		freeFormMCPToolExposure: true
		authorityDelegation:     true
		unboundedInvocation:     true
	})
})

#AdapterContract: close({
	schema: "agent.adapter-contract.v1"
	id:     #DeclaredID

	runtime:         #WorkerRuntimeAdapter
	worker?:         #DeclaredID
	workerBindingID: #DeclaredID
	workerProfileID: #DeclaredID

	executesDeclaredWork: true
	routeIDs?: [...#DeclaredID]
	declaredRouteIDs: [...#DeclaredID] & [_, ...]
	supportedEnvelopeKinds: [...#MultiAgentV2EnvelopeKind] | *["NEW_TASK", "MESSAGE", "FINAL_ANSWER"]
	payloadBoundary: #PayloadBoundary
	declaredActions: [
		"inspect" |
		"run_validation" |
		"collect_evidence",
		...,
	]

	inputAuthority:    "root_codex"
	resultAuthority:   "evidence_only"
	definesGraphTruth: false

	deny: close({
		semanticAuthority:      true
		graphTruthDefinition:   true
		freeFormToolSelection:  true
		unboundedRouteMutation: true
	})

	description?: string & !=""
})

#AdapterExecution: close({
	schema: "agent.adapter-execution.v1"
	id:     #DeclaredID

	adapterID:    #DeclaredID
	invocationID: #DeclaredID
	routeID:      #DeclaredID
	workerID:     #DeclaredID
	envelope: #MultiAgentV2RouteEnvelope & {
		routeID:   routeID
		workerID:  workerID
		adapterID: adapterID
	}

	executesDeclaredWork: true
	resultAuthority:      "evidence_only"
	definesGraphTruth:    false
})

#RuntimeRouteReference: close({
	schema:       "agent.runtime-route-reference.v1"
	routeID:      #DeclaredID
	routeKind:    #RouteKind
	context:      #RouteContextBoundary
	outputSchema: #RouteOutputSchema
})

#RouteWorkerInvocation: close({
	schema: "agent.route-worker-invocation.v1"

	routeID:   #DeclaredID
	workerID:  #DeclaredID
	profileID: #DeclaredID

	adapter: #WorkerRuntimeAdapter | *"a2a"
	a2a:     #A2AWorkerAdapter

	packet: close({
		assignedBy: "root_codex"
		bounded:    true
		context:    #RouteContextBoundary
	})

	returns: close({
		schema:           #RouteOutputSchema
		evidenceRequired: true
		authority:        "evidence_only"
	})

	deny: close({
		authorityDelegation:      true
		rawTranscriptForwarding:  true
		freeFormMCPToolExposure:  true
		sdkExecutionFromResolver: true
	})
})

#RuntimeProjection: close({
	mode: "none" | "eligible" | "requires-agent-runtime"
	routeRefs: [...#RuntimeRouteReference]
	workerInvocations?: [...#RouteWorkerInvocation]
	adapterContracts?: [...#AdapterContract]

	requirements: close({
		agentRuntimeRegistry:  "absent" | "present"
		workerAdapterRegistry: "absent" | "present" | *"absent"
		mcpRouteExecutor:      "absent" | "present"
	})

	execution: close({
		allowed:                bool
		preferredWorkerAdapter: "a2a" | *"a2a"
		secondaryWorkerAdapters: [...#WorkerRuntimeAdapter] | *["sdk-direct", "mcp", "cli"]
		requiresA2AAdapter:      bool | *true
		requiresMCPAdapter:      bool | *false
		requiresRuntimeRegistry: bool | *true
		backend:                 "none" | "codex-sdk" | "a2a"
	})

	deny: close({
		directSDKSpawn:          true
		rawTranscriptForwarding: true
		rawRegistryDump:         true
		unselectedFragments:     true
		globalMutation:          true
		authorityDelegation:     true
		freeFormMCPToolExposure: true
	})

	expectedResult: close({
		schema: "agent.route-result.v1"
	})

	if mode == "requires-agent-runtime" {
		execution: allowed: false
	}
	if execution.allowed {
		mode: "eligible"
		routeRefs: [_, ...]
		requirements: {
			agentRuntimeRegistry:  "present"
			workerAdapterRegistry: "present"
		}
		execution: {
			requiresA2AAdapter:      true
			requiresRuntimeRegistry: true
		}
	}
})
