package agentcontextresolver

import (
	sectionadapters "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver/adapters:adapters"
	sectionassertions "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver/assertions:assertions"
	sectionchecks "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver/checks:checks"
	sectionfixtures "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver/fixtures:fixtures"
	sectiongenerated "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver/generated:generated"
	graph "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver/internal/graph:graph"
	sectionhooks "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver/hooks:hooks"
	sectionprojections "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver/projections:projections"
	sectionseed "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver/seed:seed"
	sectionworkers "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver/workers:workers"
)

resolverModuleBoundary: {
	modulePath:    "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver"
	moduleRoot:    "."
	publicSurface: "domain.cue"
	deferred: ["contracts/agent-runtime"]
}

resolverSectionPackages: {
	assertions:  sectionassertions.section
	checks:      sectionchecks.section
	adapters:    sectionadapters.section
	workers:     sectionworkers.section
	hooks:       sectionhooks.section
	fixtures:    sectionfixtures.section
	projections: sectionprojections.section
	generated:   sectiongenerated.section
	seed:        sectionseed.section
}

agentContextResolver: graph.#ContractDomain & {
	id: "agent-context-resolver"

	model: {
		id:          "agent-context-resolver"
		kind:        "functional-domain"
		package:     "agentcontextresolver"
		rootPath:    "."
		description: "Contained contract domain for resolver authority, lifecycle, generated route controller packets, projections, hooks, and validation evidence."
	}

	root: {
		id:   "agent-context-resolver.root"
		kind: "contract-root"
		path: "."
		rootPath: ["agent-context-resolver.root"]
	}

	sections: {
		"agent-context-resolver.assertions": {
			kind: "assertions"
			path: "assertions"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.assertions"]
			ownedLeaves: [
				"agent-context-resolver.leaf.domain-contract",
				"agent-context-resolver.leaf.proof-contract",
			]
		}
		"agent-context-resolver.fixtures": {
			kind: "fixtures"
			path: "fixtures"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.fixtures"]
			ownedLeaves: [
				"agent-context-resolver.leaf.resolver-fixtures",
				"agent-context-resolver.leaf.workspace-lifecycle-fixtures",
			]
		}
		"agent-context-resolver.adapters": {
			kind: "adapters"
			path: "adapters"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.adapters"]
			ownedLeaves: [
				"agent-context-resolver.leaf.hook-contract",
				"agent-context-resolver.leaf.prompt-classifier-contract",
			]
		}
		"agent-context-resolver.projections": {
			kind: "projections"
			path: "projections"
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
			path: "generated"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.generated"]
			ownedLeaves: [
				"agent-context-resolver.leaf.generated-fragments",
			]
		}
		"agent-context-resolver.seeds": {
			kind: "seeds"
			path: "seed"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.seeds"]
			ownedLeaves: [
				"agent-context-resolver.leaf.seed-resolver",
			]
		}
		"agent-context-resolver.workers": {
			kind: "workers"
			path: "workers"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.workers"]
			ownedLeaves: [
				"agent-context-resolver.leaf.resolver-worker-binding",
				"agent-context-resolver.leaf.seed-worker-script",
			]
		}
		"agent-context-resolver.checks": {
			kind: "checks"
			path: "checks"
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
			path: "hooks"
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
			path:        "domain.cue"
			description: "Contained domain object model and ownership assertions."
		}
		"agent-context-resolver.leaf.proof-contract": {
			kind:   "assertion"
			parent: "agent-context-resolver.assertions"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.assertions", "agent-context-resolver.leaf.proof-contract"]
			path:        "proof.cue"
			description: "Resolver proof result and check contract."
		}
		"agent-context-resolver.leaf.resolver-fixtures": {
			kind:   "fixture"
			parent: "agent-context-resolver.fixtures"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.fixtures", "agent-context-resolver.leaf.resolver-fixtures"]
			path:        "fixtures/agent-context-resolver"
			description: "Resolver route, fragment, propagation, hook-context, and runtime-denial fixtures."
		}
		"agent-context-resolver.leaf.workspace-lifecycle-fixtures": {
			kind:   "fixture"
			parent: "agent-context-resolver.fixtures"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.fixtures", "agent-context-resolver.leaf.workspace-lifecycle-fixtures"]
			path:        "fixtures/workspace-lifecycle"
			description: "Resolver workspace lifecycle graph, edge, and packet fixtures."
		}
		"agent-context-resolver.leaf.hook-contract": {
			kind:   "adapter"
			parent: "agent-context-resolver.adapters"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.adapters", "agent-context-resolver.leaf.hook-contract"]
			path:        "hooks.cue"
			description: "Hook packet boundary and adapter evidence contract."
		}
		"agent-context-resolver.leaf.prompt-classifier-contract": {
			kind:   "adapter"
			parent: "agent-context-resolver.adapters"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.adapters", "agent-context-resolver.leaf.prompt-classifier-contract"]
			path:        "prompt_classifier.cue"
			description: "Prompt classification adapter contract for route selection evidence."
		}
		"agent-context-resolver.leaf.fragments-contract": {
			kind:   "projection"
			parent: "agent-context-resolver.projections"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.projections", "agent-context-resolver.leaf.fragments-contract"]
			path:        "fragments.cue"
			description: "Fragment registry authority projected into resolver context packets."
		}
		"agent-context-resolver.leaf.projection-contract": {
			kind:   "projection"
			parent: "agent-context-resolver.projections"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.projections", "agent-context-resolver.leaf.projection-contract"]
			path:        "projection.cue"
			description: "Resolver generated artifact projection contract."
		}
		"agent-context-resolver.leaf.runtime-projection-contract": {
			kind:   "projection"
			parent: "agent-context-resolver.projections"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.projections", "agent-context-resolver.leaf.runtime-projection-contract"]
			path:        "runtime_projection.cue"
			description: "Route reference projection contract for runtime-bound evidence."
		}
		"agent-context-resolver.leaf.registry-contract": {
			kind:   "projection"
			parent: "agent-context-resolver.projections"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.projections", "agent-context-resolver.leaf.registry-contract"]
			path:        "registry.cue"
			description: "Resolver route registry projection source."
		}
		"agent-context-resolver.leaf.generated-fragments": {
			kind:   "generated"
			parent: "agent-context-resolver.generated"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.generated", "agent-context-resolver.leaf.generated-fragments"]
			path:        "generated"
			description: "Generated resolver route, fragment, lifecycle, and turn-start evidence outputs."
		}
		"agent-context-resolver.leaf.seed-resolver": {
			kind:   "seed"
			parent: "agent-context-resolver.seeds"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.seeds", "agent-context-resolver.leaf.seed-resolver"]
			path:        "seed"
			description: "Standalone seed package for the resolver contract slice."
		}
		"agent-context-resolver.leaf.resolver-worker-binding": {
			kind:   "worker"
			parent: "agent-context-resolver.workers"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.workers", "agent-context-resolver.leaf.resolver-worker-binding"]
			path:        "resolver.cue"
			description: "Resolver output and lifecycle binding contract for generated route controller packets."
		}
		"agent-context-resolver.leaf.seed-worker-script": {
			kind:   "worker"
			parent: "agent-context-resolver.workers"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.workers", "agent-context-resolver.leaf.seed-worker-script"]
			path:        "seed/scripts"
			description: "Seed validation and generation scripts used as worker evidence."
		}
		"agent-context-resolver.leaf.gates-contract": {
			kind:   "check"
			parent: "agent-context-resolver.checks"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.checks", "agent-context-resolver.leaf.gates-contract"]
			path:        "gates.cue"
			description: "Route gate validation contract."
		}
		"agent-context-resolver.leaf.merge-contract": {
			kind:   "check"
			parent: "agent-context-resolver.checks"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.checks", "agent-context-resolver.leaf.merge-contract"]
			path:        "merge.cue"
			description: "Route result merge validation, deterministic reducer, bounded packet, and synthesis gate contract."
		}
		"agent-context-resolver.leaf.propagation-contract": {
			kind:   "check"
			parent: "agent-context-resolver.checks"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.checks", "agent-context-resolver.leaf.propagation-contract"]
			path:        "propagation.cue"
			description: "Route-local propagation validation contract."
		}
		"agent-context-resolver.leaf.route-plan-contract": {
			kind:   "check"
			parent: "agent-context-resolver.checks"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.checks", "agent-context-resolver.leaf.route-plan-contract"]
			path:        "route_plan.cue"
			description: "Route plan validation contract."
		}
		"agent-context-resolver.leaf.routes-contract": {
			kind:   "check"
			parent: "agent-context-resolver.checks"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.checks", "agent-context-resolver.leaf.routes-contract"]
			path:        "routes.cue"
			description: "Registered resolver route inventory contract."
		}
		"agent-context-resolver.leaf.sequencing-contract": {
			kind:   "check"
			parent: "agent-context-resolver.checks"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.checks", "agent-context-resolver.leaf.sequencing-contract"]
			path:        "sequencing.cue"
			description: "Route sequencing validation contract."
		}
		"agent-context-resolver.leaf.agent-context-hook": {
			kind:   "hook"
			parent: "agent-context-resolver.hooks"
			rootPath: ["agent-context-resolver.root", "agent-context-resolver.hooks", "agent-context-resolver.leaf.agent-context-hook"]
			path:        "checks/agent-context-hook"
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
		"agent-context-resolver.fixture-obligations-owned": {
			subject: "agent-context-resolver.root"
			fact:    "Every resolver fixture obligation references an existing assertion and targets a declared leaf or an explicitly planned target."
			appliesTo: [
				"agent-context-resolver.assertions",
				"agent-context-resolver.fixtures",
				"agent-context-resolver.checks",
			]
			evidence: ["agent-context-resolver.check.fixture-obligations-owned"]
			polarity: "invariant"
			strength: "required"
		}
		"agent-context-resolver.test-obligations-owned": {
			subject: "agent-context-resolver.root"
			fact:    "Every resolver test obligation references an existing assertion, existing fixture obligations, and an existing check."
			appliesTo: [
				"agent-context-resolver.assertions",
				"agent-context-resolver.fixtures",
				"agent-context-resolver.checks",
			]
			evidence: ["agent-context-resolver.check.test-obligations-owned"]
			polarity: "invariant"
			strength: "required"
		}
		"agent-context-resolver.assertion-coverage-complete": {
			subject: "agent-context-resolver.root"
			fact:    "Every active resolver assertion has declared fixture and test coverage or is explicitly coverage-exempt."
			appliesTo: [
				"agent-context-resolver.assertions",
				"agent-context-resolver.fixtures",
				"agent-context-resolver.checks",
			]
			evidence: ["agent-context-resolver.check.assertion-coverage-complete"]
			polarity: "invariant"
			strength: "required"
		}
		"agent-context-resolver.migration-acceptance-closed": {
			subject: "agent-context-resolver.root"
			fact:    "The resolver closeout can export a bounded controller packet, predefined A2A route-worker invocation schema, deterministic merge reducer, bounded merge packet, adapter bindings, and route-worker evidence without SDK subagents, MCP execution, GitButler, or git-meta."
			appliesTo: [
				"agent-context-resolver.leaf.proof-contract",
				"agent-context-resolver.leaf.merge-contract",
				"agent-context-resolver.leaf.runtime-projection-contract",
				"agent-context-resolver.leaf.route-plan-contract",
				"agent-context-resolver.leaf.routes-contract",
				"agent-context-resolver.leaf.resolver-worker-binding",
				"agent-context-resolver.leaf.generated-fragments",
			]
			evidence: ["agent-context-resolver.check.migration-acceptance-closed"]
			polarity: "invariant"
			strength: "required"
		}
	}

	fixtureObligations: {
		"agent-context-resolver.fixture.leaves-owned.positive.workspace-lifecycle-graph": {
			assertion:   "agent-context-resolver.leaves-owned"
			polarity:    "positive"
			target:      "agent-context-resolver.leaf.workspace-lifecycle-fixtures"
			path:        "fixtures/workspace-lifecycle/graph.cue"
			expected:    "pass"
			generation:  "manual"
			description: "Positive workspace lifecycle fixture proving owned leaf IDs resolve through declared section ownership."
		}
		"agent-context-resolver.fixture.leaves-owned.negative.invalid-route-authority": {
			assertion:   "agent-context-resolver.leaves-owned"
			polarity:    "negative"
			target:      "agent-context-resolver.leaf.resolver-fixtures"
			path:        "fixtures/agent-context-resolver/invalid-route-authority.cue"
			expected:    "fail"
			generation:  "manual"
			description: "Negative resolver fixture proving invalid authority ownership is rejected."
		}
		"agent-context-resolver.fixture.leaves-rooted.positive.workspace-lifecycle-packets": {
			assertion:   "agent-context-resolver.leaves-rooted"
			polarity:    "positive"
			target:      "agent-context-resolver.leaf.workspace-lifecycle-fixtures"
			path:        "fixtures/workspace-lifecycle/packets.cue"
			expected:    "pass"
			generation:  "manual"
			description: "Positive workspace lifecycle fixture proving resolver packets remain rooted in declared leaves."
		}
		"agent-context-resolver.fixture.leaves-rooted.negative.invalid-route-fragment": {
			assertion:   "agent-context-resolver.leaves-rooted"
			polarity:    "negative"
			target:      "agent-context-resolver.leaf.resolver-fixtures"
			path:        "fixtures/agent-context-resolver/invalid-route-fragment.cue"
			expected:    "fail"
			generation:  "manual"
			description: "Negative resolver fixture proving invalid route fragment ownership fails rooted-leaf validation."
		}
		"agent-context-resolver.fixture.migration-acceptance.positive.route-compiler-proof": {
			assertion:   "agent-context-resolver.migration-acceptance-closed"
			polarity:    "positive"
			target:      "agent-context-resolver.leaf.proof-contract"
			path:        "proof.cue"
			expected:    "pass"
			generation:  "manual"
			description: "Positive proof fixture for the generated controller packet, runtime-denied route-worker invocation model, deterministic reducer, bounded merge packet, and evidence-only closeout."
		}
	}

	testObligations: {
		"agent-context-resolver.test.sections-contained.cue-vet": {
			assertion: "agent-context-resolver.sections-contained"
			fixtures: []
			check: "agent-context-resolver.check.sections-contained"
			command: ["cue vet ."]
			description: "Validate section containment through the resolver domain CUE package."
		}
		"agent-context-resolver.test.leaves-owned.cue-vet": {
			assertion: "agent-context-resolver.leaves-owned"
			fixtures: [
				"agent-context-resolver.fixture.leaves-owned.positive.workspace-lifecycle-graph",
				"agent-context-resolver.fixture.leaves-owned.negative.invalid-route-authority",
			]
			check: "agent-context-resolver.check.leaves-owned"
			command: ["cue vet ."]
			description: "Validate leaf ownership with positive and negative resolver fixture obligations declared as evidence inputs."
		}
		"agent-context-resolver.test.leaves-rooted.cue-eval": {
			assertion: "agent-context-resolver.leaves-rooted"
			fixtures: [
				"agent-context-resolver.fixture.leaves-rooted.positive.workspace-lifecycle-packets",
				"agent-context-resolver.fixture.leaves-rooted.negative.invalid-route-fragment",
			]
			check: "agent-context-resolver.check.leaves-rooted"
			command: ["cue eval . -e agentContextResolver -c"]
			description: "Validate leaf root paths with positive and negative resolver fixture obligations declared as evidence inputs."
		}
		"agent-context-resolver.test.fixture-obligations-owned.cue-eval": {
			assertion: "agent-context-resolver.fixture-obligations-owned"
			fixtures: []
			check: "agent-context-resolver.check.fixture-obligations-owned"
			command: ["cue eval . -e agentContextResolver -c"]
			description: "Validate fixture obligation assertion and target references through graph constraints."
		}
		"agent-context-resolver.test.test-obligations-owned.cue-eval": {
			assertion: "agent-context-resolver.test-obligations-owned"
			fixtures: [
				"agent-context-resolver.fixture.leaves-owned.positive.workspace-lifecycle-graph",
				"agent-context-resolver.fixture.leaves-owned.negative.invalid-route-authority",
				"agent-context-resolver.fixture.leaves-rooted.positive.workspace-lifecycle-packets",
				"agent-context-resolver.fixture.leaves-rooted.negative.invalid-route-fragment",
			]
			check: "agent-context-resolver.check.test-obligations-owned"
			command: ["cue eval . -e agentContextResolver -c"]
			description: "Validate test obligation assertion, fixture, and check references through graph constraints."
		}
		"agent-context-resolver.test.assertion-coverage-complete.cue-eval": {
			assertion: "agent-context-resolver.assertion-coverage-complete"
			fixtures: [
				"agent-context-resolver.fixture.leaves-owned.positive.workspace-lifecycle-graph",
				"agent-context-resolver.fixture.leaves-owned.negative.invalid-route-authority",
				"agent-context-resolver.fixture.leaves-rooted.positive.workspace-lifecycle-packets",
				"agent-context-resolver.fixture.leaves-rooted.negative.invalid-route-fragment",
			]
			check: "agent-context-resolver.check.assertion-coverage-complete"
			command: ["cue eval . -e agentContextResolver -c"]
			description: "Validate active assertion coverage through graph constraints."
		}
		"agent-context-resolver.test.migration-acceptance-closed.cue-export": {
			assertion: "agent-context-resolver.migration-acceptance-closed"
			fixtures: ["agent-context-resolver.fixture.migration-acceptance.positive.route-compiler-proof"]
			check: "agent-context-resolver.check.migration-acceptance-closed"
			command: [
				"cue export . -e agentContextResolver",
				"cue export . -e routeInventory",
				"cue export . -e routeInventoryValidation",
				"cue export . -e routeCompilerProof",
				"cue export . -e agentContextResolver.checkManifest",
				"cue export . -e agentContextResolver.validationCertificate",
			]
			description: "Validate the final resolver migration acceptance exports, including route compiler proof closeout state."
		}
	}

	coverage: {
		"agent-context-resolver.coverage.sections-contained": {
			assertion: "agent-context-resolver.sections-contained"
			requiredFixtures: []
			requiredTests: ["agent-context-resolver.test.sections-contained.cue-vet"]
		}
		"agent-context-resolver.coverage.leaves-owned": {
			assertion: "agent-context-resolver.leaves-owned"
			requiredFixtures: [
				"agent-context-resolver.fixture.leaves-owned.positive.workspace-lifecycle-graph",
				"agent-context-resolver.fixture.leaves-owned.negative.invalid-route-authority",
			]
			requiredTests: ["agent-context-resolver.test.leaves-owned.cue-vet"]
		}
		"agent-context-resolver.coverage.leaves-rooted": {
			assertion: "agent-context-resolver.leaves-rooted"
			requiredFixtures: [
				"agent-context-resolver.fixture.leaves-rooted.positive.workspace-lifecycle-packets",
				"agent-context-resolver.fixture.leaves-rooted.negative.invalid-route-fragment",
			]
			requiredTests: ["agent-context-resolver.test.leaves-rooted.cue-eval"]
		}
		"agent-context-resolver.coverage.fixture-obligations-owned": {
			assertion: "agent-context-resolver.fixture-obligations-owned"
			requiredFixtures: []
			requiredTests: ["agent-context-resolver.test.fixture-obligations-owned.cue-eval"]
		}
		"agent-context-resolver.coverage.test-obligations-owned": {
			assertion: "agent-context-resolver.test-obligations-owned"
			requiredFixtures: [
				"agent-context-resolver.fixture.leaves-owned.positive.workspace-lifecycle-graph",
				"agent-context-resolver.fixture.leaves-owned.negative.invalid-route-authority",
				"agent-context-resolver.fixture.leaves-rooted.positive.workspace-lifecycle-packets",
				"agent-context-resolver.fixture.leaves-rooted.negative.invalid-route-fragment",
			]
			requiredTests: ["agent-context-resolver.test.test-obligations-owned.cue-eval"]
		}
		"agent-context-resolver.coverage.assertion-coverage-complete": {
			assertion: "agent-context-resolver.assertion-coverage-complete"
			requiredFixtures: [
				"agent-context-resolver.fixture.leaves-owned.positive.workspace-lifecycle-graph",
				"agent-context-resolver.fixture.leaves-owned.negative.invalid-route-authority",
				"agent-context-resolver.fixture.leaves-rooted.positive.workspace-lifecycle-packets",
				"agent-context-resolver.fixture.leaves-rooted.negative.invalid-route-fragment",
			]
			requiredTests: ["agent-context-resolver.test.assertion-coverage-complete.cue-eval"]
		}
		"agent-context-resolver.coverage.migration-acceptance-closed": {
			assertion: "agent-context-resolver.migration-acceptance-closed"
			requiredFixtures: ["agent-context-resolver.fixture.migration-acceptance.positive.route-compiler-proof"]
			requiredTests: ["agent-context-resolver.test.migration-acceptance-closed.cue-export"]
		}
	}

	checks: {
		"agent-context-resolver.check.sections-contained": {
			kind: "cue-vet"
			assertions: ["agent-context-resolver.sections-contained"]
			target: "agent-context-resolver.root"
			command: ["cue vet ."]
			failure: "agent-context-resolver contains an orphaned, mis-owned, or unproven contract section."
		}
		"agent-context-resolver.check.leaves-owned": {
			kind: "cue-vet"
			assertions: ["agent-context-resolver.leaves-owned"]
			target: "agent-context-resolver.root"
			command: ["cue vet ."]
			failure: "agent-context-resolver contains a section-owned leaf ID that does not resolve to a declared leaf with the section as parent."
		}
		"agent-context-resolver.check.leaves-rooted": {
			kind: "cue-def"
			assertions: ["agent-context-resolver.leaves-rooted"]
			target: "agent-context-resolver.root"
			command: ["cue eval . -e agentContextResolver -c"]
			expr:    "agentContextResolver"
			failure: "agent-context-resolver contains a declared leaf without a root path beginning at agent-context-resolver.root."
		}
		"agent-context-resolver.check.fixture-obligations-owned": {
			kind: "cue-def"
			assertions: ["agent-context-resolver.fixture-obligations-owned"]
			target: "agent-context-resolver.root"
			command: ["cue eval . -e agentContextResolver -c"]
			expr:    "agentContextResolver"
			failure: "agent-context-resolver contains a fixture obligation with an orphaned assertion or target."
		}
		"agent-context-resolver.check.test-obligations-owned": {
			kind: "cue-def"
			assertions: ["agent-context-resolver.test-obligations-owned"]
			target: "agent-context-resolver.root"
			command: ["cue eval . -e agentContextResolver -c"]
			expr:    "agentContextResolver"
			failure: "agent-context-resolver contains a test obligation with an orphaned assertion, fixture obligation, or check."
		}
		"agent-context-resolver.check.assertion-coverage-complete": {
			kind: "cue-def"
			assertions: ["agent-context-resolver.assertion-coverage-complete"]
			target: "agent-context-resolver.root"
			command: ["cue eval . -e agentContextResolver -c"]
			expr:    "agentContextResolver"
			failure: "agent-context-resolver contains an active assertion without declared coverage."
		}
		"agent-context-resolver.check.migration-acceptance-closed": {
			kind: "cue-export"
			assertions: ["agent-context-resolver.migration-acceptance-closed"]
			target: "agent-context-resolver.root"
			command: [
				"cue export . -e agentContextResolver",
				"cue export . -e routeInventory",
				"cue export . -e routeInventoryValidation",
				"cue export . -e routeCompilerProof",
				"cue export . -e agentContextResolver.checkManifest",
				"cue export . -e agentContextResolver.validationCertificate",
			]
			expr:    "routeCompilerProof"
			failure: "agent-context-resolver migration acceptance is not closed by exported controller packet, route-worker invocation, deterministic reducer, bounded merge packet, adapter binding, and evidence records."
		}
	}

	checkManifest: graph.#CheckManifest & {
		id:     "agent-context-resolver.check-manifest"
		domain: "agent-context-resolver"
		entries: {
			for obligationID, obligation in testObligations {
				"\(obligationID)": {
					testObligation: obligationID
					check:          obligation.check
					assertion:      obligation.assertion
					fixtures:       obligation.fixtures
					command:        obligation.command
					evidenceRequired: {
						assertions: [obligation.assertion]
						fixtures: obligation.fixtures
						check:    obligation.check
					}
				}
			}
		}
	}

	validationCertificate: graph.#ValidationCertificate & {
		id:       "agent-context-resolver.validation-certificate"
		domain:   "agent-context-resolver"
		manifest: checkManifest.id
		entries: {
			for entryID, entry in checkManifest.entries {
				"\(entryID)": {
					manifestEntry:  entry.id
					testObligation: entry.testObligation
					check:          entry.check
					assertion:      entry.assertion
					requiredEvidence: {
						assertions: entry.evidenceRequired.assertions
						fixtures:   entry.evidenceRequired.fixtures
						check:      entry.evidenceRequired.check
						command:    entry.command
					}
				}
			}
		}
	}

	_checkManifestTestObligationRefs: {
		for _, entry in checkManifest.entries {
			"\(entry.id)": testObligations[entry.testObligation]
		}
	}

	_checkManifestCheckRefs: {
		for _, entry in checkManifest.entries {
			"\(entry.id)": checks[entry.check]
		}
	}

	_validationCertificateManifestRefs: {
		for _, entry in validationCertificate.entries {
			"\(entry.id)": checkManifest.entries[entry.manifestEntry]
		}
	}

	workers: {
		"agent-context-resolver.validation-worker": {
			kind:      "validation-worker"
			objective: "Validate agent-context-resolver contract-domain assertions."
			profile: {
				id:               "agent-context-resolver.a2a-worker"
				runtime:          "a2a"
				preferredRuntime: "a2a"
				secondaryAdapters: ["sdk-direct", "mcp", "cli"]
				a2a: {
					runtime:                          "a2a"
					preferred:                        true
					offloadsContext:                  true
					offloadsRouteLocalResponsibility: true
					offloadsAuthority:                false
					inputAuthority:                   "root_codex"
					resultAuthority:                  "evidence_only"
					description:                      "Preferred adapter for bounded route-worker invocation packets."
				}
				controlInvariants: [
					"Adapters execute declared work.",
					"Adapters do not define graph truth.",
					"Workers return evidence, not final authority.",
					"Evidence records report observed results.",
					"Checks declare expected evidence.",
				]
			}
			runtimeAdapter: "a2a"
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
				"agent-context-resolver.fixture-obligations-owned",
				"agent-context-resolver.test-obligations-owned",
				"agent-context-resolver.assertion-coverage-complete",
				"agent-context-resolver.migration-acceptance-closed",
			]
			pathScope: {
				allowedPaths: [
					"domain.cue",
					".",
					"generated",
					"fixtures/agent-context-resolver",
					"fixtures/workspace-lifecycle",
					"seed",
					"checks/agent-context-hook",
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
			protocolSurface: {
				responseItemMetadata: {
					turn_id: "optional"
				}
				sourceIdentityRequired: true
				supportedEnvelopeKinds: ["NEW_TASK", "MESSAGE", "FINAL_ANSWER"]
				payloadBoundary: {
					plaintextEnvelope:               true
					encryptedContent:                true
					plaintextCarriesCorrelationOnly: true
					encryptedContentOpaque:          true
					definesGraphTruth:               false
					mutationAuthority:               false
				}
				authority:         "correlation_only"
				definesGraphTruth: false
				mutationAuthority: false
			}
		}
	}

	adapters: {
		"agent-context-resolver.a2a-adapter": graph.#AdapterContract & #AdapterContract & {
			schema:               "agent.adapter-contract.v1"
			runtime:              "a2a"
			worker:               "agent-context-resolver.validation-worker"
			workerBindingID:      "agent-context-resolver.validation-worker"
			workerProfileID:      "agent-context-resolver.a2a-worker"
			executesDeclaredWork: true
			declaredActions: ["inspect", "run_validation", "collect_evidence"]
			routeIDs: [
				"resolver.inspect.current",
				"resolver.plan.compile",
				"vcs.patch-stack.inspect",
				"mcp.evidence.inspect",
				"agent-skill.projection.validate",
				"resolver.context-packet.inspect",
				"repo.lifecycle.validate",
			]
			declaredRouteIDs: routeIDs
			supportedEnvelopeKinds: ["NEW_TASK", "MESSAGE", "FINAL_ANSWER"]
			payloadBoundary: {
				plaintextEnvelope:               true
				encryptedContent:                true
				plaintextCarriesCorrelationOnly: true
				encryptedContentOpaque:          true
				definesGraphTruth:               false
				mutationAuthority:               false
			}
			inputAuthority:    "root_codex"
			resultAuthority:   "evidence_only"
			definesGraphTruth: false
			deny: {
				semanticAuthority:      true
				graphTruthDefinition:   true
				freeFormToolSelection:  true
				unboundedRouteMutation: true
			}
			description: "A2A route-worker adapter contract for executing declared resolver route work and returning evidence-only results."
		}
	}

	evidenceRecords: {
		"agent-context-resolver.evidence.route-worker-output": graph.#EvidenceRecord & #EvidenceRecord & {
			schema:             "agent.evidence-record.v1"
			kind:               "route-worker-evidence"
			routeID:            "resolver.inspect.current"
			workerID:           "agent-context-resolver.validation-worker"
			profileID:          "agent-context-resolver.a2a-worker"
			adapterID:          "agent-context-resolver.a2a-adapter"
			invocationID:       "agent-context-resolver.invocation.resolver-inspect-current"
			adapterExecutionID: "agent-context-resolver.adapter-execution.resolver-inspect-current"
			routeResultID:      "agent-context-resolver.route-result.resolver-inspect-current"
			adapter:            "a2a"
			responseItemMetadata: {
				turn_id: "agent-context-resolver.turn.resolver-inspect-current"
			}
			sourceIdentity: {
				sourceKind:     "response_item"
				sourceID:       "agent-context-resolver.response-item.resolver-inspect-current"
				producerID:     "agent-context-resolver.validation-worker"
				responseItemID: "resp-item-resolver-inspect-current"
			}
			routeEnvelope: {
				schema:    "codex.multi-agent.route-envelope.v2"
				kind:      "FINAL_ANSWER"
				routeID:   "resolver.inspect.current"
				workerID:  "agent-context-resolver.validation-worker"
				adapterID: "agent-context-resolver.a2a-adapter"
				metadata: {
					turn_id: "agent-context-resolver.turn.resolver-inspect-current"
				}
				sourceIdentity: {
					sourceKind:     "response_item"
					sourceID:       "agent-context-resolver.response-item.resolver-inspect-current"
					producerID:     "agent-context-resolver.validation-worker"
					responseItemID: "resp-item-resolver-inspect-current"
				}
				taskName:  "/agent-context-resolver/validation"
				recipient: "/root-codex"
				sender:    "/agent-context-resolver/validation-worker"
				payload: {
					id:   routeResultID
					kind: "final_answer"
				}
				payloadBoundary: {
					plaintextEnvelope:               true
					encryptedContent:                true
					plaintextCarriesCorrelationOnly: true
					encryptedContentOpaque:          true
					definesGraphTruth:               false
					mutationAuthority:               false
				}
				authority:         "correlation_only"
				definesGraphTruth: false
				mutationAuthority: false
			}
			payloadBoundary: {
				plaintextEnvelope:               true
				encryptedContent:                true
				plaintextCarriesCorrelationOnly: true
				encryptedContentOpaque:          true
				definesGraphTruth:               false
				mutationAuthority:               false
			}
			status:  "partial"
			summary: "Template evidence record for a bounded route-worker output observed through the declared A2A adapter."
			observedEvidence: [
				{kind: "contract", ref: "routes.cue"},
				{kind: "contract", ref: "resolver.cue"},
			]
			reportsObservedResults: true
			checksExpectedEvidence: true
			authority:              "evidence_only"
			definesGraphTruth:      false
			mutationAuthority:      false
			description:            "Evidence records bind route-worker invocation, adapter execution, and route result observations without becoming semantic authority."
		}
	}

	hooks: {}
}
