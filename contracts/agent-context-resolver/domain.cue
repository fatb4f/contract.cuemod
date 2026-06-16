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
			ownedLeaves: []
		}
		"agent-context-resolver.fixtures": {
			kind: "fixtures"
			path: "contracts/agent-context-resolver/fixtures"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.fixtures"]
			ownedLeaves: []
		}
		"agent-context-resolver.adapters": {
			kind: "adapters"
			path: "contracts/agent-context-resolver/adapters"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.adapters"]
			ownedLeaves: []
		}
		"agent-context-resolver.projections": {
			kind: "projections"
			path: "contracts/agent-context-resolver/projections"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.projections"]
			ownedLeaves: []
		}
		"agent-context-resolver.generated": {
			kind: "generated"
			path: "contracts/agent-context-resolver/generated"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.generated"]
			ownedLeaves: []
		}
		"agent-context-resolver.seeds": {
			kind: "seeds"
			path: "contracts/agent-context-resolver/seeds"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.seeds"]
			ownedLeaves: []
		}
		"agent-context-resolver.workers": {
			kind: "workers"
			path: "contracts/agent-context-resolver/workers"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.workers"]
			ownedLeaves: []
		}
		"agent-context-resolver.checks": {
			kind: "checks"
			path: "contracts/agent-context-resolver/checks"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.checks"]
			ownedLeaves: []
		}
		"agent-context-resolver.hooks": {
			kind: "hooks"
			path: "contracts/agent-context-resolver/hooks"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.hooks"]
			ownedLeaves: []
		}
	}

	leaves: {}

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
	}

	checks: {
		"agent-context-resolver.check.sections-contained": {
			kind: "cue-vet"
			assertions: ["agent-context-resolver.sections-contained"]
			target: "agent-context-resolver.root"
			command: ["cue vet ./contracts/agent-context-resolver"]
			failure: "agent-context-resolver contains an orphaned, mis-owned, or unproven contract section."
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
			requiredAssertions: ["agent-context-resolver.sections-contained"]
			pathScope: {
				allowedPaths: ["contracts/agent-context-resolver"]
				deniedPaths: []
			}
			actions: ["inspect", "run_validation", "collect_evidence"]
			mayMutate: false
		}
	}

	hooks: {}
}
