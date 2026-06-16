# Contract Domain Migration Template

Use this template for each `contracts/*` migration. Replace every
`<contract-id>` and `<package-name>` placeholder before turning the sketch into
repository CUE.

This is a migration template, not executable authority. The executable base
schema belongs in `contracts/graph`, and worker request/result/action/budget
semantics stay owned by `contracts/agent-runtime/sdk_workers.cue`.

## Target Layout

Each migrated contract should converge on this contained shape:

```text
contracts/<contract-id>
  assertions/
  fixtures/
  adapters/
  projections/
  generated/
  seeds/
  workers/
  checks/
  hooks/
```

External leaves are allowed only as explicit migration glue. Every external
leaf must still have an authority path back to the contract root.

## Domain Skeleton

```cue
package <package-name>

import graph "github.com/fatb4f/contract.cuemod/contracts/graph"

<contractValue>: graph.#ContractDomain & {
	id: "<contract-id>"

	model: {
		id: "<contract-id>"
		kind: "functional-domain"
		package: "<package-name>"
		rootPath: "contracts/<contract-id>"
	}

	graph: {
		root: "<contract-id>.root"

		nodes: {
			"<contract-id>.root": {
				kind: "root"
				path: "contracts/<contract-id>"
				rootPath: ["<contract-id>.root"]
			}

			"<contract-id>.assertions": {
				kind: "assertion"
				path: "contracts/<contract-id>/assertions"
				parent: "<contract-id>.root"
				rootPath: [
					"<contract-id>.root",
					"<contract-id>.assertions",
				]
			}

			"<contract-id>.fixtures": {
				kind: "fixture"
				path: "contracts/<contract-id>/fixtures"
				parent: "<contract-id>.root"
				rootPath: [
					"<contract-id>.root",
					"<contract-id>.fixtures",
				]
			}

			"<contract-id>.adapters": {
				kind: "adapter"
				path: "contracts/<contract-id>/adapters"
				parent: "<contract-id>.root"
				rootPath: [
					"<contract-id>.root",
					"<contract-id>.adapters",
				]
			}

			"<contract-id>.projections": {
				kind: "projection"
				path: "contracts/<contract-id>/projections"
				parent: "<contract-id>.root"
				rootPath: [
					"<contract-id>.root",
					"<contract-id>.projections",
				]
			}

			"<contract-id>.generated": {
				kind: "generated"
				path: "contracts/<contract-id>/generated"
				parent: "<contract-id>.root"
				rootPath: [
					"<contract-id>.root",
					"<contract-id>.generated",
				]
			}

			"<contract-id>.seeds": {
				kind: "seed"
				path: "contracts/<contract-id>/seeds"
				parent: "<contract-id>.root"
				rootPath: [
					"<contract-id>.root",
					"<contract-id>.seeds",
				]
			}

			"<contract-id>.workers": {
				kind: "worker"
				path: "contracts/<contract-id>/workers"
				parent: "<contract-id>.root"
				rootPath: [
					"<contract-id>.root",
					"<contract-id>.workers",
				]
			}

			"<contract-id>.checks": {
				kind: "check"
				path: "contracts/<contract-id>/checks"
				parent: "<contract-id>.root"
				rootPath: [
					"<contract-id>.root",
					"<contract-id>.checks",
				]
			}

			"<contract-id>.hooks": {
				kind: "hook"
				path: "contracts/<contract-id>/hooks"
				parent: "<contract-id>.root"
				rootPath: [
					"<contract-id>.root",
					"<contract-id>.hooks",
				]
			}
		}

		authorityEdges: [
			{from: "<contract-id>.root", to: "<contract-id>.assertions", kind: "owns"},
			{from: "<contract-id>.root", to: "<contract-id>.fixtures", kind: "owns"},
			{from: "<contract-id>.root", to: "<contract-id>.adapters", kind: "owns"},
			{from: "<contract-id>.root", to: "<contract-id>.projections", kind: "owns"},
			{from: "<contract-id>.root", to: "<contract-id>.generated", kind: "owns"},
			{from: "<contract-id>.root", to: "<contract-id>.seeds", kind: "owns"},
			{from: "<contract-id>.root", to: "<contract-id>.workers", kind: "owns"},
			{from: "<contract-id>.root", to: "<contract-id>.checks", kind: "owns"},
			{from: "<contract-id>.root", to: "<contract-id>.hooks", kind: "owns"},
		]

		relationEdges: []

		branches: {
			assertions: {kind: "contract", rootNode: "<contract-id>.assertions", ownedNodes: ["<contract-id>.assertions"]}
			fixtures: {kind: "fixture", rootNode: "<contract-id>.fixtures", ownedNodes: ["<contract-id>.fixtures"]}
			adapters: {kind: "adapter", rootNode: "<contract-id>.adapters", ownedNodes: ["<contract-id>.adapters"]}
			projections: {kind: "projection", rootNode: "<contract-id>.projections", ownedNodes: ["<contract-id>.projections"]}
			generated: {kind: "generated", rootNode: "<contract-id>.generated", ownedNodes: ["<contract-id>.generated"]}
			seeds: {kind: "seed", rootNode: "<contract-id>.seeds", ownedNodes: ["<contract-id>.seeds"]}
			workers: {kind: "worker", rootNode: "<contract-id>.workers", ownedNodes: ["<contract-id>.workers"]}
			checks: {kind: "test", rootNode: "<contract-id>.checks", ownedNodes: ["<contract-id>.checks"]}
			hooks: {kind: "hook", rootNode: "<contract-id>.hooks", ownedNodes: ["<contract-id>.hooks"]}
		}
	}

	assertions: {
		"<contract-id>.root-contained": {
			subject: "<contract-id>.root"
			fact: "Every owned leaf has a declared authority path back to the contract root."
			appliesTo: [
				"<contract-id>.assertions",
				"<contract-id>.fixtures",
				"<contract-id>.adapters",
				"<contract-id>.projections",
				"<contract-id>.generated",
				"<contract-id>.seeds",
				"<contract-id>.workers",
				"<contract-id>.checks",
				"<contract-id>.hooks",
			]
			evidence: ["<contract-id>.check.root-contained"]
			polarity: "invariant"
			strength: "required"
		}
	}

	checks: {
		"<contract-id>.check.root-contained": {
			kind: "cue-vet"
			assertions: ["<contract-id>.root-contained"]
			target: "<contract-id>.root"
			command: ["cue vet ./contracts/<contract-id>"]
			failure: "Contract domain contains an orphaned, mis-owned, or unproven leaf."
		}
	}

	workers: {
		"<contract-id>.validation-worker": {
			kind: "validation-worker"
			objective: "Validate <contract-id> contract-domain assertions."
			allowedNodes: [
				"<contract-id>.root",
				"<contract-id>.assertions",
				"<contract-id>.fixtures",
				"<contract-id>.adapters",
				"<contract-id>.projections",
				"<contract-id>.generated",
				"<contract-id>.seeds",
				"<contract-id>.workers",
				"<contract-id>.checks",
				"<contract-id>.hooks",
			]
			deniedNodes: []
			requiredAssertions: ["<contract-id>.root-contained"]
			actions: ["inspect", "run_validation", "collect_evidence"]
			mayMutate: false
		}
	}

	hooks: {}

	adapters: {}
	fixtures: {}
	projections: {}
	generated: {}
	seeds: {}
}
```

## Migration Checklist

1. Declare the root node and contained branch nodes first.
2. Add current external leaves as migration nodes only when needed.
3. Give every non-root node a `parent` and full `rootPath`.
4. Use `authorityEdges` only for ownership/containment.
5. Use `relationEdges` for `asserts`, `evidences`, `validates`, `derives`,
   `projects`, `guards`, `depends_on`, and `adapts`.
6. Add assertions as contract-owned facts before adding checks.
7. Bind workers through `#WorkerBinding`; do not redefine worker runtime
   request/result/action/budget semantics.
8. Keep shell, hooks, and just recipes as adapters.
