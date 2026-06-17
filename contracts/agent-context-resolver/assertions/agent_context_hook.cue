package assertions

import (
	"list"
	"strings"

	agentprojection "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver/projections/agent-skill:agentskillprojection"
)

agentContextResolverAssertions: {
	agentContextHook: {
		hookEvent:                     "UserPromptSubmit"
		emptyResultForUnmatchedPrompt: true
		additionalContextPrefix:       "Agent route controller packet:\n"

		generatedFrom: {
			turnStart:      "contracts/agent-context-resolver/generated/turn_start_fragments.json"
			promptRoutes:   "contracts/agent-context-resolver/generated/prompt_routes.json"
			routeInventory: "contracts/agent-context-resolver/generated/route_inventory.json"
		}

		projection: {
			hooks: agentprojection.projection.hooks & {
				hooks: UserPromptSubmit: [{
					hooks: [{
						type:          "command"
						command:       ".codex/skills/resolve-agent-context/scripts/agent-context-resolver-hook"
						timeout:       10
						statusMessage: "Routing repository contract context"
					}]
				}]
			}
			skillContent: agentprojection.skillContent & !~"(^|/)bin/"
			scripts: {
				"agent-context-resolver-hook": agentprojection.projection.scripts["agent-context-resolver-hook"] & {
					path:       ".codex/skills/resolve-agent-context/scripts/agent-context-resolver-hook"
					executable: true
					content:    agentprojection.agentContextResolverHook & !~"dotfiles-agent-context-hook"
				}
				"resolve-agent-context": agentprojection.projection.scripts["resolve-agent-context"] & {
					path:       ".codex/skills/resolve-agent-context/scripts/resolve-agent-context"
					executable: true
					content:    agentprojection.resolveAgentContext & !~"dotfiles-agent-context-hook"
				}
			}
		}

		packet: {
			schema:               "agent.route-controller-packet.v1"
			availableFragmentIDs: agentContextResolverAssertions.agentContextHook.generatedAssets.turnStart.fragmentIDs
			selectedFragments: ["agent-context-resolver.authority", "agent-skill.projection", "mcp.evidence-plane"]
			compactHintsContain:      "resolver-authority"
			evidenceSource:           "user_prompt"
			generatedFrom:            agentContextResolverAssertions.agentContextHook.generatedFrom
			resolverCommand:          ".codex/skills/resolve-agent-context/scripts/resolve-agent-context"
			resolverSkill:            ".codex/skills/resolve-agent-context/SKILL.md"
			allSelectedAreAvailable:  true
			allRoutesAreRegistered:   true
			allRuntimeRefsRegistered: true

			for id in selectedFragments {
				if !list.Contains(availableFragmentIDs, id) {
					_selectedFragmentMissingFromTurnStart: _|_
				}
			}

			controller: {
				schema:               "agent.route-plan.v1"
				plannerKind:          "generated_controller_packet"
				authority:            "resolver_projection"
				availableFragmentIDs: agentContextResolverAssertions.agentContextHook.packet.availableFragmentIDs
				availableRouteIDs:    agentContextResolverAssertions.agentContextHook.generatedAssets.routeInventory.routeIDs
				selectedFragments:    agentContextResolverAssertions.agentContextHook.packet.selectedFragments
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
					},
					{
						id:       "resolver.plan.compile"
						kind:     "validate"
						priority: 95
						sequence: 20
						dependsOn: ["resolver.inspect.current"]
						inputFragments: ["agent-context-resolver.authority"]
						task: {
							objective: "Compile and validate a generated route controller packet."
							constraints: [
								"Reference registered routes and selected fragments only.",
								"Keep root Codex as merge and synthesis authority.",
								"Do not execute routes or spawn SDK subagents during route planning.",
							]
						}
						outputSchema: {schema: "agent.route-result.validation.v1"}
						gates: ["registry-authority", "route-local-propagation", "runtime-deny", "structured-result"]
					},
				]
				propagation: {
					mode:                    "route-local"
					denyFullTranscript:      true
					denyRawRegistryDump:     true
					denyUnselectedFragments: true
					requireStructuredResult: true
				}
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
						for route in routes {
							schema:       "agent.runtime-route-reference.v1"
							routeID:      route.id
							routeKind:    route.kind
							outputSchema: route.outputSchema
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

				for route in routes {
					if !list.Contains(availableRouteIDs, route.id) {
						_selectedRouteMissingFromInventory: _|_
					}
				}
				for ref in runtime.routeRefs {
					if !list.Contains([for route in routes {route.id}], ref.routeID) {
						_runtimeRefMissingSelectedRoute: _|_
					}
				}
			}
		}

		generatedAssets: {
			turnStart: {
				generatedFrom: "registry.index.json"
				fragmentIDs: [
					"agent-context-resolver.authority",
					"agent-runtime.authority",
					"agent-skill.projection",
					"mcp.evidence-plane",
					"repo.contract-seed",
					"repo.lifecycle",
					"resolver.context-packet",
					"vb-contract.authority",
					"vb-contract.component-seed",
					"vb-contract.contract-seed",
					"vb-contract.virtual-branch",
					"vcs.patch-stack",
				]
			}
			promptRoutes: {
				generatedFrom: "turn_start_fragments.json"
				requiredRoutes: [
					{id: "resolver", selects: ["agent-context-resolver.authority"], invokes: ["resolver.inspect.current", "resolver.plan.compile"]},
					{id: "mcp", selects: ["mcp.evidence-plane"], invokes: ["mcp.evidence.inspect"]},
					{id: "skill", selects: ["agent-skill.projection"], invokes: ["agent-skill.projection.validate"]},
					{id: "repo", selects: ["repo.lifecycle"], invokes: ["repo.lifecycle.validate"]},
				]
			}
			routeInventory: {
				generatedFrom: "contracts/agent-context-resolver/routes.cue"
				routeIDs: [
					"resolver.inspect.current",
					"resolver.plan.compile",
					"vcs.patch-stack.inspect",
					"mcp.evidence.inspect",
					"agent-skill.projection.validate",
					"resolver.context-packet.inspect",
					"repo.lifecycle.validate",
				]
				gateIDs: ["registry-authority", "route-local-propagation", "runtime-deny", "structured-result"]
			}
		}

		_containsExpectedResolverTerms: strings.Contains(agentprojection.agentContextResolverHook, "denyFullTranscript") &&
			strings.Contains(agentprojection.agentContextResolverHook, "denyRawRegistryDump") &&
			strings.Contains(agentprojection.agentContextResolverHook, "denyUnselectedFragments") &&
			strings.Contains(agentprojection.agentContextResolverHook, "directSDKSpawn") &&
			strings.Contains(agentprojection.resolveAgentContext, "Agent route controller packet:")
	}
}
