package agentcontextresolver

import graph "github.com/fatb4f/contract.cuemod/contracts/graph"

agentContextResolver: graph.#ContractDomain & {
	id: "agent-context-resolver"

	model: {
		id:          "agent-context-resolver"
		kind:        "functional-domain"
		package:     "agentcontextresolver"
		rootPath:    "contracts/agent-context-resolver"
		description: "Contained contract domain for resolver authority, lifecycle, route planning, projections, hooks, and validation evidence."
	}

	root: {
		id:   "agent-context-resolver.root"
		kind: "contract-root"
		path: "contracts/agent-context-resolver"
		rootPath: ["agent-context-resolver.root"]
	}

	sections: {
		"agent-context-resolver.assertions": {
			kind: "assertions"
			path: "contracts/agent-context-resolver/assertions"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.assertions"]
			ownedLeaves: [
				"agent-context-resolver.leaf.domain-contract",
				"agent-context-resolver.leaf.proof-contract",
			]
		}
		"agent-context-resolver.fixtures": {
			kind: "fixtures"
			path: "contracts/agent-context-resolver/fixtures"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.fixtures"]
			ownedLeaves: [
				"agent-context-resolver.leaf.resolver-fixtures",
				"agent-context-resolver.leaf.workspace-lifecycle-fixtures",
			]
		}
		"agent-context-resolver.adapters": {
			kind: "adapters"
			path: "contracts/agent-context-resolver/adapters"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.adapters"]
			ownedLeaves: [
				"agent-context-resolver.leaf.hook-contract",
				"agent-context-resolver.leaf.prompt-classifier-contract",
			]
		}
		"agent-context-resolver.projections": {
			kind: "projections"
			path: "contracts/agent-context-resolver/projections"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.projections"]
			ownedLeaves: [
				"agent-context-resolver.leaf.fragments-contract",
				"agent-context-resolver.leaf.projection-contract",
				"agent-context-resolver.leaf.runtime-projection-contract",
				"agent-context-resolver.leaf.registry-contract",
			]
		}
		"agent-context-resolver.generated": {
			kind: "generated"
			path: "contracts/agent-context-resolver/generated"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.generated"]
			ownedLeaves: [
				"agent-context-resolver.leaf.generated-fragments",
			]
		}
		"agent-context-resolver.seeds": {
			kind: "seeds"
			path: "contracts/agent-context-resolver/seeds"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.seeds"]
			ownedLeaves: [
				"agent-context-resolver.leaf.seed-resolver",
			]
		}
		"agent-context-resolver.workers": {
			kind: "workers"
			path: "contracts/agent-context-resolver/workers"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.workers"]
			ownedLeaves: [
				"agent-context-resolver.leaf.resolver-worker-binding",
				"agent-context-resolver.leaf.seed-worker-script",
			]
		}
		"agent-context-resolver.checks": {
			kind: "checks"
			path: "contracts/agent-context-resolver/checks"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.checks"]
			ownedLeaves: [
				"agent-context-resolver.leaf.gates-contract",
				"agent-context-resolver.leaf.merge-contract",
				"agent-context-resolver.leaf.propagation-contract",
				"agent-context-resolver.leaf.route-plan-contract",
				"agent-context-resolver.leaf.routes-contract",
				"agent-context-resolver.leaf.sequencing-contract",
			]
		}
		"agent-context-resolver.hooks": {
			kind: "hooks"
			path: "contracts/agent-context-resolver/hooks"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.hooks"]
			ownedLeaves: [
				"agent-context-resolver.leaf.agent-context-hook",
			]
		}
	}

	leaves: {
		"agent-context-resolver.leaf.domain-contract": {
			kind:   "assertion"
			parent: "agent-context-resolver.assertions"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.assertions", "agent-context-resolver.leaf.domain-contract"]
			path:        "contracts/agent-context-resolver/domain.cue"
			description: "Contained domain object model and ownership assertions."
		}
		"agent-context-resolver.leaf.proof-contract": {
			kind:   "assertion"
			parent: "agent-context-resolver.assertions"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.assertions", "agent-context-resolver.leaf.proof-contract"]
			path:        "contracts/agent-context-resolver/proof.cue"
			description: "Resolver proof result and check contract."
		}
		"agent-context-resolver.leaf.resolver-fixtures": {
			kind:   "fixture"
			parent: "agent-context-resolver.fixtures"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.fixtures", "agent-context-resolver.leaf.resolver-fixtures"]
			path:        "fixtures/resolver/agent-context-resolver"
			description: "Resolver route, fragment, propagation, hook-context, and runtime-denial fixtures."
		}
		"agent-context-resolver.leaf.workspace-lifecycle-fixtures": {
			kind:   "fixture"
			parent: "agent-context-resolver.fixtures"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.fixtures", "agent-context-resolver.leaf.workspace-lifecycle-fixtures"]
			path:        "fixtures/resolver/workspace-lifecycle"
			description: "Resolver workspace lifecycle graph, edge, and packet fixtures."
		}
		"agent-context-resolver.leaf.hook-contract": {
			kind:   "adapter"
			parent: "agent-context-resolver.adapters"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.adapters", "agent-context-resolver.leaf.hook-contract"]
			path:        "contracts/agent-context-resolver/hooks.cue"
			description: "Hook packet boundary and adapter evidence contract."
		}
		"agent-context-resolver.leaf.prompt-classifier-contract": {
			kind:   "adapter"
			parent: "agent-context-resolver.adapters"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.adapters", "agent-context-resolver.leaf.prompt-classifier-contract"]
			path:        "contracts/agent-context-resolver/prompt_classifier.cue"
			description: "Prompt classification adapter contract for route selection evidence."
		}
		"agent-context-resolver.leaf.fragments-contract": {
			kind:   "projection"
			parent: "agent-context-resolver.projections"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.projections", "agent-context-resolver.leaf.fragments-contract"]
			path:        "contracts/agent-context-resolver/fragments.cue"
			description: "Fragment registry authority projected into resolver context packets."
		}
		"agent-context-resolver.leaf.projection-contract": {
			kind:   "projection"
			parent: "agent-context-resolver.projections"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.projections", "agent-context-resolver.leaf.projection-contract"]
			path:        "contracts/agent-context-resolver/projection.cue"
			description: "Resolver generated artifact projection contract."
		}
		"agent-context-resolver.leaf.runtime-projection-contract": {
			kind:   "projection"
			parent: "agent-context-resolver.projections"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.projections", "agent-context-resolver.leaf.runtime-projection-contract"]
			path:        "contracts/agent-context-resolver/runtime_projection.cue"
			description: "Route reference projection contract for runtime-bound evidence."
		}
		"agent-context-resolver.leaf.registry-contract": {
			kind:   "projection"
			parent: "agent-context-resolver.projections"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.projections", "agent-context-resolver.leaf.registry-contract"]
			path:        "contracts/agent-context-resolver/registry.cue"
			description: "Resolver route registry projection source."
		}
		"agent-context-resolver.leaf.generated-fragments": {
			kind:   "generated"
			parent: "agent-context-resolver.generated"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.generated", "agent-context-resolver.leaf.generated-fragments"]
			path:        "generated/agent-context-resolver"
			description: "Generated resolver route, fragment, lifecycle, and turn-start evidence outputs."
		}
		"agent-context-resolver.leaf.seed-resolver": {
			kind:   "seed"
			parent: "agent-context-resolver.seeds"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.seeds", "agent-context-resolver.leaf.seed-resolver"]
			path:        "seeds/contract-cuemod/agent-context-resolver"
			description: "Standalone seed package for the resolver contract slice."
		}
		"agent-context-resolver.leaf.resolver-worker-binding": {
			kind:   "worker"
			parent: "agent-context-resolver.workers"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.workers", "agent-context-resolver.leaf.resolver-worker-binding"]
			path:        "contracts/agent-context-resolver/resolver.cue"
			description: "Resolver worker route packet and lifecycle binding contract."
		}
		"agent-context-resolver.leaf.seed-worker-script": {
			kind:   "worker"
			parent: "agent-context-resolver.workers"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.workers", "agent-context-resolver.leaf.seed-worker-script"]
			path:        "seeds/contract-cuemod/agent-context-resolver/scripts"
			description: "Seed validation and generation scripts used as worker evidence."
		}
		"agent-context-resolver.leaf.gates-contract": {
			kind:   "check"
			parent: "agent-context-resolver.checks"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.checks", "agent-context-resolver.leaf.gates-contract"]
			path:        "contracts/agent-context-resolver/gates.cue"
			description: "Route gate validation contract."
		}
		"agent-context-resolver.leaf.merge-contract": {
			kind:   "check"
			parent: "agent-context-resolver.checks"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.checks", "agent-context-resolver.leaf.merge-contract"]
			path:        "contracts/agent-context-resolver/merge.cue"
			description: "Route result merge validation contract."
		}
		"agent-context-resolver.leaf.propagation-contract": {
			kind:   "check"
			parent: "agent-context-resolver.checks"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.checks", "agent-context-resolver.leaf.propagation-contract"]
			path:        "contracts/agent-context-resolver/propagation.cue"
			description: "Route-local propagation validation contract."
		}
		"agent-context-resolver.leaf.route-plan-contract": {
			kind:   "check"
			parent: "agent-context-resolver.checks"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.checks", "agent-context-resolver.leaf.route-plan-contract"]
			path:        "contracts/agent-context-resolver/route_plan.cue"
			description: "Route plan validation contract."
		}
		"agent-context-resolver.leaf.routes-contract": {
			kind:   "check"
			parent: "agent-context-resolver.checks"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.checks", "agent-context-resolver.leaf.routes-contract"]
			path:        "contracts/agent-context-resolver/routes.cue"
			description: "Registered resolver route inventory contract."
		}
		"agent-context-resolver.leaf.sequencing-contract": {
			kind:   "check"
			parent: "agent-context-resolver.checks"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.checks", "agent-context-resolver.leaf.sequencing-contract"]
			path:        "contracts/agent-context-resolver/sequencing.cue"
			description: "Route sequencing validation contract."
		}
		"agent-context-resolver.leaf.agent-context-hook": {
			kind:   "hook"
			parent: "agent-context-resolver.hooks"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.hooks", "agent-context-resolver.leaf.agent-context-hook"]
			path:        "test/agent-context-hook.sh"
			description: "Hook regression script that validates projected resolver packet evidence."
		}
	}

	authorityEdges: [
		{from: "agent-context-resolver.root", to: "agent-context-resolver.assertions", kind: "owns"},
		{from: "agent-context-resolver.root", to: "agent-context-resolver.fixtures", kind: "owns"},
		{from: "agent-context-resolver.root", to: "agent-context-resolver.adapters", kind: "owns"},
		{from: "agent-context-resolver.root", to: "agent-context-resolver.projections", kind: "owns"},
		{from: "agent-context-resolver.root", to: "agent-context-resolver.generated", kind: "owns"},
		{from: "agent-context-resolver.root", to: "agent-context-resolver.seeds", kind: "owns"},
		{from: "agent-context-resolver.root", to: "agent-context-resolver.workers", kind: "owns"},
		{from: "agent-context-resolver.root", to: "agent-context-resolver.checks", kind: "owns"},
		{from: "agent-context-resolver.root", to: "agent-context-resolver.hooks", kind: "owns"},
	]

	relations: []

	_ownedLeavesResolve: [
		for _, section in sections
		for _, leafID in section.ownedLeaves {
			leaves[leafID] & {
				parent: section.id
			}
		},
	]

	assertions: {
		"agent-context-resolver.sections-contained": {
			subject: "agent-context-resolver.root"
			fact:    "Every agent-context-resolver contract section has a declared authority path back to the contract root."
			appliesTo: [
				"agent-context-resolver.assertions",
				"agent-context-resolver.fixtures",
				"agent-context-resolver.adapters",
				"agent-context-resolver.projections",
				"agent-context-resolver.generated",
				"agent-context-resolver.seeds",
				"agent-context-resolver.workers",
				"agent-context-resolver.checks",
				"agent-context-resolver.hooks",
			]
			evidence: ["agent-context-resolver.check.sections-contained"]
			polarity: "invariant"
			strength: "required"
		}
		"agent-context-resolver.leaves-owned": {
			subject: "agent-context-resolver.root"
			fact:    "Every section-owned agent-context-resolver leaf ID resolves to a declared leaf with that section as parent."
			appliesTo: [
				"agent-context-resolver.assertions",
				"agent-context-resolver.fixtures",
				"agent-context-resolver.adapters",
				"agent-context-resolver.projections",
				"agent-context-resolver.generated",
				"agent-context-resolver.seeds",
				"agent-context-resolver.workers",
				"agent-context-resolver.checks",
				"agent-context-resolver.hooks",
			]
			evidence: ["agent-context-resolver.check.leaves-owned"]
			polarity: "invariant"
			strength: "required"
		}
		"agent-context-resolver.leaves-rooted": {
			subject: "agent-context-resolver.root"
			fact:    "Every declared agent-context-resolver leaf has a root path beginning at the agent-context-resolver contract root."
			appliesTo: [
				"agent-context-resolver.leaf.domain-contract",
				"agent-context-resolver.leaf.proof-contract",
				"agent-context-resolver.leaf.resolver-fixtures",
				"agent-context-resolver.leaf.workspace-lifecycle-fixtures",
				"agent-context-resolver.leaf.hook-contract",
				"agent-context-resolver.leaf.prompt-classifier-contract",
				"agent-context-resolver.leaf.fragments-contract",
				"agent-context-resolver.leaf.projection-contract",
				"agent-context-resolver.leaf.runtime-projection-contract",
				"agent-context-resolver.leaf.registry-contract",
				"agent-context-resolver.leaf.generated-fragments",
				"agent-context-resolver.leaf.seed-resolver",
				"agent-context-resolver.leaf.resolver-worker-binding",
				"agent-context-resolver.leaf.seed-worker-script",
				"agent-context-resolver.leaf.gates-contract",
				"agent-context-resolver.leaf.merge-contract",
				"agent-context-resolver.leaf.propagation-contract",
				"agent-context-resolver.leaf.route-plan-contract",
				"agent-context-resolver.leaf.routes-contract",
				"agent-context-resolver.leaf.sequencing-contract",
				"agent-context-resolver.leaf.agent-context-hook",
			]
			evidence: ["agent-context-resolver.check.leaves-rooted"]
			polarity: "invariant"
			strength: "required"
		}
	}

	checks: {
		"agent-context-resolver.check.sections-contained": {
			kind: "cue-vet"
			assertions: ["agent-context-resolver.sections-contained"]
			target: "agent-context-resolver.root"
			command: ["cue vet ./contracts/agent-context-resolver"]
			failure: "agent-context-resolver contains an orphaned, mis-owned, or unproven contract section."
		}
		"agent-context-resolver.check.leaves-owned": {
			kind: "cue-vet"
			assertions: ["agent-context-resolver.leaves-owned"]
			target: "agent-context-resolver.root"
			command: ["cue vet ./contracts/agent-context-resolver"]
			failure: "agent-context-resolver contains a section-owned leaf ID that does not resolve to a declared leaf with the section as parent."
		}
		"agent-context-resolver.check.leaves-rooted": {
			kind: "cue-def"
			assertions: ["agent-context-resolver.leaves-rooted"]
			target: "agent-context-resolver.root"
			command: ["cue eval ./contracts/agent-context-resolver -e agentContextResolver -c"]
			expr:    "agentContextResolver"
			failure: "agent-context-resolver contains a declared leaf without a root path beginning at agent-context-resolver.root."
		}
	}

	workers: {
		"agent-context-resolver.validation-worker": {
			kind:      "validation-worker"
			objective: "Validate agent-context-resolver contract-domain assertions."
			allowedNodes: [
				"agent-context-resolver.root",
				"agent-context-resolver.assertions",
				"agent-context-resolver.fixtures",
				"agent-context-resolver.adapters",
				"agent-context-resolver.projections",
				"agent-context-resolver.generated",
				"agent-context-resolver.seeds",
				"agent-context-resolver.workers",
				"agent-context-resolver.checks",
				"agent-context-resolver.hooks",
			]
			deniedNodes: []
			requiredAssertions: [
				"agent-context-resolver.sections-contained",
				"agent-context-resolver.leaves-owned",
				"agent-context-resolver.leaves-rooted",
			]
			pathScope: {
				allowedPaths: [
					"contracts/agent-context-resolver/domain.cue",
					"contracts/agent-context-resolver",
					"generated/agent-context-resolver",
					"fixtures/resolver/agent-context-resolver",
					"fixtures/resolver/workspace-lifecycle",
					"seeds/contract-cuemod/agent-context-resolver",
					"test/agent-context-hook.sh",
				]
				deniedPaths: [
					"contracts/repo",
					"contracts/agent-runtime",
					"contracts/agent-skill",
					"contracts/providers",
					"contracts/adapters",
				]
			}
			actions: ["inspect", "run_validation", "collect_evidence"]
			mayMutate:       false
			resultAuthority: "evidence_only"
		}
	}

	hooks: {}
}
