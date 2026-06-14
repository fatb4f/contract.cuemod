package agentcontextresolver

import "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver:agentcontextresolver"

registry: agentcontextresolver.#Registry & {
	fragments: [
		{id: "fragment-workspace-lifecycle", surface: "turn_start", channel: "message", itemKind: "message", expectedNativeContextInjection: true, label: "workspace lifecycle fragment"},
		{id: "fragment-desktop-session", surface: "turn_start", channel: "message", itemKind: "message", expectedNativeContextInjection: true, label: "desktop session fragment"},
	]
}

classification: agentcontextresolver.#PromptClassification & {
	selectedFragments: ["fragment-workspace-lifecycle"]
	hints: {
		domain:        "workspace"
		workflow:      "sessionizer"
		authorityRoot: "contracts/agent-context-resolver"
	}
	evidence: {
		matchedRules: ["turn_start_fragment", "known_fragment"]
		rejectedRules: ["mcp_tool_output", "assembled_context_body"]
	}
}

turnStart: agentcontextresolver.#TurnStartContextFragmentSet & {
	fragments: registry.fragments
}

output: agentcontextresolver.#ResolverOutput & {
	prompt: "How does the WezTerm sessionizer switch workspaces?"
	report: {
		schema:         "agent.context-resolver.lifecycle-report.v1"
		registry:       registry
		turnStart:      turnStart
		classification: classification
		assertions: [
			{name: "turn_start_available", passed: true},
			{name: "known_fragment_selected", passed: true},
			{name: "context_body_not_assembled", passed: true},
		]
	}
	hook: {
		hook_event_name:   "UserPromptSubmit"
		selectedFragments: classification.selectedFragments
		hints:             classification.hints
		evidence:          classification.evidence
		additionalContext: "Agent context lifecycle report: selected fragment IDs only"
	}
}

#FixtureRoute: agentcontextresolver.#RouteInvocation & {
	id:            string | *"resolver.inspect.current"
	kind:          "inspect"
	priority:      100
	sequence:      10
	parallelGroup: "inspect"
	dependsOn: [...string] | *[]
	inputFragments: [...string] | *["agent-context-resolver.authority"]
	task: {
		objective: "Inspect resolver authority."
		constraints: ["Use selected fragments only."]
		files: ["contracts/agent-context-resolver"]
	}
	outputSchema: {schema: "agent.route-result.inspect.v1"}
	gates: ["registry-authority", "route-local-propagation", "structured-result"]
}

#FixturePlan: agentcontextresolver.#ResolvedRoutePlan & {
	schema: "agent.route-plan.v1"
	turnID: "fixture-turn"
	intent: "resolver"
	availableFragmentIDs: [...string] | *["agent-context-resolver.authority"]
	availableRouteIDs: [...string] | *["resolver.inspect.current"]
	selectedFragments: [...string] | *["agent-context-resolver.authority"]
	routes: [...agentcontextresolver.#RouteInvocation] | *[#FixtureRoute]
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
					objective: "Inspect resolver authority."
					acceptedFacts: []
					selectedFragments: ["agent-context-resolver.authority"]
					files: ["contracts/agent-context-resolver"]
				}
				excludes: ["full transcript", "unselected fragments", "raw registry", "unbounded tool logs", "irrelevant route outputs"]
				return: {
					schema: {schema: "agent.route-result.inspect.v1"}
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
	gates: [
		{
			id:    "registry-authority"
			class: "registry_authority"
			stage: "selection"
			appliesToKinds: ["inspect"]
			required: true
		},
	]
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
		routeRefs: [{
			schema:    "agent.runtime-route-reference.v1"
			routeID:   "resolver.inspect.current"
			routeKind: "inspect"
			context:   validRoutePlan.propagation.perRoute["resolver.inspect.current"]
			outputSchema: {schema: "agent.route-result.inspect.v1"}
		}]
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

validRoutePlan: #FixturePlan
