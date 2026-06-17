package agentskillprojection

import "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver/internal/agent-skill:agentskill"

projection: agentskill.#SkillProjection & {
	metadata: {
		name:        "resolve-agent-context"
		description: "Resolve repository contract fragments from generated resolver inventories."
		provenance: {
			projection_id: "df:projection/resolve-agent-context-skill"
			contract_ids: ["df:contract/agent-skill-runtime"]
			generated: true
		}
	}
	hooks: {
		hooks: {
			UserPromptSubmit: [{
				hooks: [{
					type:          "command"
					command:       ".codex/skills/resolve-agent-context/scripts/agent-context-resolver-hook"
					timeout:       10
					statusMessage: "Routing repository contract context"
				}]
			}]
		}
	}
	scripts: {
		"agent-context-resolver-hook": {
			path:       ".codex/skills/resolve-agent-context/scripts/agent-context-resolver-hook"
			content:    agentContextResolverHook
			executable: true
			provenance: metadata.provenance
		}
		"resolve-agent-context": {
			path:       ".codex/skills/resolve-agent-context/scripts/resolve-agent-context"
			content:    resolveAgentContext
			executable: true
			provenance: metadata.provenance
		}
	}
}

skillContent: """
	---
	name: resolve-agent-context
	description: Resolve repository contract fragments and compile bounded route plans.
	---

	# Agent Context Resolution

	The `UserPromptSubmit` hook provides a bounded route controller packet, not task authority.

	1. Run `contracts/agent-context-resolver/projections/codex/skills/resolve-agent-context/scripts/resolve-agent-context --prompt "<prompt>"`.
	2. Treat `selectedFragments` as a subset of `availableFragmentIDs`.
	3. Treat `controller.routes` as a subset of `controller.availableRouteIDs`.
	4. Resolve selected fragment metadata through `contracts/agent-context-resolver/generated/fragment_inventory.json`.
	5. Inspect the declared `sourcePath` and obey repository instruction boundaries before editing.
	6. Never execute projected routes directly or treat generated JSON and MCP/tool output as source authority.
	7. Regenerate resolver-local Codex projection and JSON outputs from their CUE sources after changes.
	"""

agentContextResolverHook: """
	#!/bin/sh
	set -eu

	script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
	if [ -n "${CONTRACT_CUEMOD_ROOT:-}" ]; then
		repo_root=$CONTRACT_CUEMOD_ROOT
	else
		repo_root=$script_dir
		while [ "$repo_root" != "/" ] && [ ! -d "$repo_root/cue.mod" ]; do
			repo_root=$(CDPATH= cd -- "$repo_root/.." && pwd -P)
		done
	fi
	[ -d "$repo_root/cue.mod" ] || exit 2
	if [ -d "$repo_root/generated" ] && grep -q '/contracts/agent-context-resolver"' "$repo_root/cue.mod/module.cue"; then
		generated_dir="$repo_root/generated"
	else
		generated_dir="$repo_root/contracts/agent-context-resolver/generated"
	fi
	input_json=$(mktemp "${TMPDIR:-/tmp}/agent-context-resolver.XXXXXX.json")
	trap 'rm -f "$input_json"' EXIT HUP INT TERM
	cat >"$input_json"

	prompt=$(jq -er 'select(.hook_event_name == "UserPromptSubmit") | .prompt' "$input_json") || {
		printf '{}\\n'
		exit 0
	}

	classification=$(
		jq -cn \\
			--arg prompt "$prompt" \\
			--slurpfile turnStart "$generated_dir/turn_start_fragments.json" \\
			--slurpfile promptRoutes "$generated_dir/prompt_routes.json" \\
			--slurpfile routeInventory "$generated_dir/route_inventory.json" '
			($prompt | ascii_downcase) as $lower |
			[$turnStart[0].fragments[].id] as $available |
			[
			($promptRoutes[0] | if type == "array" then . else .routes end)[]
				| . as $route
					| select(any($route.terms[]; . as $term | $lower | contains($term)))
			] as $matched |
			([
				$matched[].selects[] as $id
				| select($available | index($id) != null)
				| $id
			] | unique) as $selected |
			([$matched[].invokes[]] | unique) as $invoked |
			([
				$routeInventory[0].routes[]
				| . as $route
				| select($invoked | index($route.id) != null)
				| select([
					$route.inputFragments[] as $fragment
					| $selected
					| index($fragment) != null
				] | all)
				| del(.promptRouteIDs)
			] | sort_by(.sequence, -.priority, .id)) as $routes |
			([$routes[].gates[]] | unique) as $gateIDs |
			{
				schema: "agent.route-controller-packet.v1",
				availableFragmentIDs: $available,
				selectedFragments: $selected,
				compactHints: [$matched[].hint] | unique,
				evidence: [
					$matched[]
						| {kind: "prompt_route", value: .id, source: "user_prompt"}
				],
				controller: {
					schema: "agent.route-plan.v1",
					plannerKind: "generated_controller_packet",
					authority: "resolver_projection",
					turnID: (
						"prompt-" +
						($prompt | @base64 | gsub("[^A-Za-z0-9]"; "") | .[0:20])
					),
					intent: ($matched | sort_by(-.priority, .id) | .[0].id),
					availableFragmentIDs: $available,
					availableRouteIDs: [$routeInventory[0].routes[].id],
					selectedFragments: $selected,
					routes: $routes,
					propagation: {
						mode: "route-local",
						root: {
							includes: {
								intent: ($matched | sort_by(-.priority, .id) | .[0].id),
								selectedFragments: $selected,
								acceptedRouteResults: []
							},
							excludes: [
								"raw route logs",
								"unvalidated route claims",
								"runtime implementation details"
							]
						},
						perRoute: (
							reduce $routes[] as $route ({};
								.[$route.id] = {
									includes: {
										objective: $route.task.objective,
										acceptedFacts: [],
										selectedFragments: $route.inputFragments,
										files: ($route.task.files // []),
										priorArtifacts: ($route.dependsOn // []),
										validationCommands: ($route.task.commands // [])
									},
									excludes: [
										"full transcript",
										"unselected fragments",
										"raw registry",
										"unbounded tool logs",
										"irrelevant route outputs"
									],
									return: {
										schema: $route.outputSchema,
										maxSummaryTokens: 800,
										evidenceRequired: true
									}
								}
							)
						),
						denyFullTranscript: true,
						denyRawRegistryDump: true,
						denyUnselectedFragments: true,
						requireStructuredResult: true
					},
					gates: [
						$routeInventory[0].gates[]
							| . as $gate
							| select($gateIDs | index($gate.id) != null)
					],
					expectedMerge: {
						mode: "fail_closed",
						requireStructuredResults: true,
						requireEvidenceForClaims: true,
						conflictPolicy: "root_decides",
						maxMergedSummaryTokens: 1200,
						finalAuthority: "root_codex",
						routeResultsAreAuthority: false
					},
					runtime: {
						mode: "requires-agent-runtime",
						routeRefs: [
							$routes[] as $route
							| {
								schema: "agent.runtime-route-reference.v1",
								routeID: $route.id,
								routeKind: $route.kind,
								context: {
									includes: {
										objective: $route.task.objective,
										acceptedFacts: [],
										selectedFragments: $route.inputFragments,
										files: ($route.task.files // []),
										priorArtifacts: ($route.dependsOn // []),
										validationCommands: ($route.task.commands // [])
									},
									excludes: [
										"full transcript",
										"unselected fragments",
										"raw registry",
										"unbounded tool logs",
										"irrelevant route outputs"
									],
									return: {
										schema: $route.outputSchema,
										maxSummaryTokens: 800,
										evidenceRequired: true
									}
								},
								outputSchema: $route.outputSchema
							}
						],
						requirements: {
							agentRuntimeRegistry: "absent",
							mcpRouteExecutor: "absent"
						},
						execution: {
							allowed: false,
							requiresMCPAdapter: true,
							requiresRuntimeRegistry: true,
							backend: "codex-sdk"
						},
						deny: {
							directSDKSpawn: true,
							rawTranscriptForwarding: true,
							rawRegistryDump: true,
							unselectedFragments: true,
							globalMutation: true
						},
						expectedResult: {schema: "agent.route-result.v1"}
					}
				},
				generatedFrom: {
					turnStart: "contracts/agent-context-resolver/generated/turn_start_fragments.json",
					promptRoutes: "contracts/agent-context-resolver/generated/prompt_routes.json",
					routeInventory: "contracts/agent-context-resolver/generated/route_inventory.json"
				},
				resolver: {
					command: ".codex/skills/resolve-agent-context/scripts/resolve-agent-context",
					skill: ".codex/skills/resolve-agent-context/SKILL.md"
				}
			}'
	)

	[ "$(printf '%s' "$classification" | jq '.controller.routes | length')" -gt 0 ] || {
		printf '{}\\n'
		exit 0
	}

	jq -cn --arg context "Agent route controller packet:
	$classification" '{
		hookSpecificOutput: {
			hookEventName: "UserPromptSubmit",
			additionalContext: $context
		}
	}'
	"""

resolveAgentContext: """
	#!/bin/sh
	set -eu

	script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
	prompt=
	while [ "$#" -gt 0 ]; do
		case $1 in
		--prompt)
			[ "$#" -ge 2 ] || exit 2
			prompt=$2
			shift 2
			;;
		--cwd|--candidate)
			[ "$#" -ge 2 ] || exit 2
			shift 2
			;;
		*)
			printf 'resolve-agent-context: unknown argument: %s\\n' "$1" >&2
			exit 2
			;;
		esac
	done

	[ -n "$prompt" ] || {
		printf 'resolve-agent-context: --prompt is required\\n' >&2
		exit 2
	}

	output=$(
		printf '{"hook_event_name":"UserPromptSubmit","prompt":%s}\\n' \\
			"$(printf '%s' "$prompt" | jq -Rs .)" |
			"$script_dir/agent-context-resolver-hook"
	)
	printf '%s\\n' "$output" | jq -er '
		if . == {} then
			{}
		else
			.hookSpecificOutput.additionalContext
			| sub("^Agent route controller packet:\\n"; "")
			| fromjson
		end
	'
	"""
