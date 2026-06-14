package agentcontextresolver

import "list"

#PromptIntent: #DeclaredID

#RouteKind:
	"inspect" |
	"validate" |
	"generate" |
	"diff" |
	"test" |
	"summarize" |
	"risk_scan"

#RouteTask: close({
	objective: string & !=""
	constraints: [...string & !=""]
	files?: [...string & !=""]
	commands?: [...string & !=""]
})

#RouteOutputSchema: close({
	schema: string & !=""
})

#RouteInvocation: close({
	id:             #DeclaredID
	kind:           #RouteKind
	priority:       int & >=0
	sequence:       int & >=0
	parallelGroup?: #DeclaredID
	dependsOn: [...#DeclaredID]
	inputFragments: [...#DeclaredID] & [_, ...]
	task:         #RouteTask
	outputSchema: #RouteOutputSchema
	gates: [...#DeclaredID] & [_, ...]
})

#RegisteredRoute: close({
	#RouteInvocation
	promptRouteIDs: [...#DeclaredID] & [_, ...]
})

#RouteInventory: close({
	generatedFrom: "contracts/agent-context-resolver/routes.cue"
	routes: [...#RegisteredRoute] & [_, ...]
	gates: [...#Gate] & [_, ...]
})

routeInventory: #RouteInventory & {
	generatedFrom: "contracts/agent-context-resolver/routes.cue"
	gates:         gateInventory
	routes: [
		{
			id:            "resolver.inspect.current"
			kind:          "inspect"
			priority:      100
			sequence:      10
			parallelGroup: "inspect"
			dependsOn: []
			inputFragments: ["agent-context-resolver.authority"]
			task: {
				objective: "Inspect the current resolver authority and generated boundary."
				constraints: ["Treat CUE and repository state as durable authority."]
				files: ["contracts/agent-context-resolver"]
			}
			outputSchema: {schema: "agent.route-result.inspect.v1"}
			gates: ["registry-authority", "route-local-propagation", "structured-result"]
			promptRouteIDs: ["resolver"]
		},
		{
			id:       "resolver.plan.compile"
			kind:     "validate"
			priority: 95
			sequence: 20
			dependsOn: ["resolver.inspect.current"]
			inputFragments: ["agent-context-resolver.authority"]
			task: {
				objective: "Compile and validate a bounded route plan."
				constraints: [
					"Reference registered routes and selected fragments only.",
					"Keep root Codex as merge and synthesis authority.",
				]
			}
			outputSchema: {schema: "agent.route-result.validation.v1"}
			gates: ["registry-authority", "route-local-propagation", "runtime-deny", "structured-result"]
			promptRouteIDs: ["resolver"]
		},
		{
			id:            "vcs.patch-stack.inspect"
			kind:          "inspect"
			priority:      80
			sequence:      10
			parallelGroup: "inspect"
			dependsOn: []
			inputFragments: ["vcs.patch-stack"]
			task: {
				objective: "Inspect the declared patch-stack workflow."
				constraints: ["Do not mutate repository state during route inspection."]
			}
			outputSchema: {schema: "agent.route-result.inspect.v1"}
			gates: ["registry-authority", "route-local-propagation", "structured-result"]
			promptRouteIDs: ["patch-stack"]
		},
		{
			id:            "mcp.evidence.inspect"
			kind:          "inspect"
			priority:      80
			sequence:      10
			parallelGroup: "inspect"
			dependsOn: []
			inputFragments: ["mcp.evidence-plane"]
			task: {
				objective: "Inspect MCP evidence-plane constraints."
				constraints: ["Do not promote tool output into implied context."]
			}
			outputSchema: {schema: "agent.route-result.inspect.v1"}
			gates: ["registry-authority", "route-local-propagation", "structured-result"]
			promptRouteIDs: ["mcp"]
		},
		{
			id:       "agent-skill.projection.validate"
			kind:     "validate"
			priority: 70
			sequence: 20
			dependsOn: []
			inputFragments: ["agent-skill.projection"]
			task: {
				objective: "Validate generated agent skill and hook projections."
				constraints: ["Regenerate derived assets from CUE authority."]
				commands: ["./test/agent-context-hook.sh"]
			}
			outputSchema: {schema: "agent.route-result.validation.v1"}
			gates: ["registry-authority", "route-local-propagation", "structured-result"]
			promptRouteIDs: ["skill"]
		},
		{
			id:            "resolver.context-packet.inspect"
			kind:          "inspect"
			priority:      70
			sequence:      10
			parallelGroup: "inspect"
			dependsOn: []
			inputFragments: ["resolver.context-packet"]
			task: {
				objective: "Inspect context packet projection constraints."
				constraints: ["Return structured evidence without forwarding parent context."]
			}
			outputSchema: {schema: "agent.route-result.inspect.v1"}
			gates: ["registry-authority", "route-local-propagation", "structured-result"]
			promptRouteIDs: ["context-packet"]
		},
		{
			id:       "repo.lifecycle.validate"
			kind:     "validate"
			priority: 70
			sequence: 20
			dependsOn: []
			inputFragments: ["repo.lifecycle"]
			task: {
				objective: "Validate repository lifecycle and generated-output boundaries."
				constraints: ["Do not treat generated artifacts as source authority."]
				commands: ["./test/check.sh"]
			}
			outputSchema: {schema: "agent.route-result.validation.v1"}
			gates: ["registry-authority", "route-local-propagation", "structured-result"]
			promptRouteIDs: ["repo"]
		},
	]
}

_availableFragmentIDs: [for fragment in turnStartFragmentSet.fragments {fragment.id}]
_registeredRouteIDs: [for route in routeInventory.routes {route.id}]
_registeredGateIDs: [for gate in routeInventory.gates {gate.id}]

routeInventoryValidation: {
	for route in routeInventory.routes {
		for fragmentID in route.inputFragments {
			if !list.Contains(_availableFragmentIDs, fragmentID) {
				_invalidFragment: _|_
			}
		}
		for gateID in route.gates {
			if !list.Contains(_registeredGateIDs, gateID) {
				_invalidGate: _|_
			}
		}
		for dependencyID in route.dependsOn {
			if !list.Contains(_registeredRouteIDs, dependencyID) {
				_invalidDependency: _|_
			}
		}
	}
}
