# Contract Domain Migration Template

Use this template for each `contracts/*` migration. Replace every
`<contract-id>`, `<package-name>`, and `<contractValue>` placeholder before
turning the sketch into repository CUE.

This is a migration template, not executable authority. The executable base
schema belongs in `contracts/graph`, and worker request/result/action/budget
semantics stay owned by `contracts/agent-runtime/sdk_workers.cue`.

The key distinction is:

```text
sections
  = contained contract-local categories

leaves
  = concrete fixture/check/hook/generated/etc. files or values under sections
```

Do not model `fixtures`, `checks`, `hooks`, or `generated` as separate domain
branches. They are sections inside one `ContractDomain`.

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

## GitHub Issue Slice Mapping

This template is designed to work with `.github/ISSUE_TEMPLATE/agent_slice.yml`.
Use the issue mode to decide which section may change:

| Issue mode | Contract section | What belongs here | What does not belong here |
| --- | --- | --- | --- |
| `contract-only` | `assertions`, root schema | Contract facts, authority tree shape, section/leaf declarations | Concrete positive/negative fixture bodies |
| `fixture-only` | `fixtures` | Concrete valid/invalid examples that exercise existing assertions | New invariant design or broad validation wiring |
| validation sub-issue | `checks` | `cue vet`, `cue export`, fixture polarity, freshness, hook regression commands as evidence | Test data fixtures or runtime hook code |
| `projection-refresh` | `projections`, `generated` | Derived outputs and freshness evidence | Source authority changes |
| `hook-runtime` | `hooks`, `adapters` | Hook boundaries and shell/Codex adapters that enforce authority | Contract fact design unless explicitly scoped |
| `repo/vcs-only` | repo/VCS owned leaves only | Repo workflow or VCS contract leaves | Domain fixture/check changes outside the issue scope |
| `issue-admin` | no contract section | GitHub comments, sub-issue creation, closeout summaries | CUE/schema/source edits |

When a slice needs multiple sections, create sub-issues instead of widening the
parent issue. For example, fixture work and validation/check work are separate:
fixtures provide data; checks provide executable evidence.

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

	root: {
		id: "<contract-id>.root"
		kind: "contract-root"
		path: "contracts/<contract-id>"
		rootPath: ["<contract-id>.root"]
	}

	sections: {
		assertions: {
			id: "<contract-id>.assertions"
			kind: "assertions"
			parent: "<contract-id>.root"
			path: "contracts/<contract-id>/assertions"
			rootPath: [
				"<contract-id>.root",
				"<contract-id>.assertions",
			]
			ownedLeaves: []
		}

		fixtures: {
			id: "<contract-id>.fixtures"
			kind: "fixtures"
			parent: "<contract-id>.root"
			path: "contracts/<contract-id>/fixtures"
			rootPath: [
				"<contract-id>.root",
				"<contract-id>.fixtures",
			]
			ownedLeaves: []
		}

		adapters: {
			id: "<contract-id>.adapters"
			kind: "adapters"
			parent: "<contract-id>.root"
			path: "contracts/<contract-id>/adapters"
			rootPath: [
				"<contract-id>.root",
				"<contract-id>.adapters",
			]
			ownedLeaves: []
		}

		projections: {
			id: "<contract-id>.projections"
			kind: "projections"
			parent: "<contract-id>.root"
			path: "contracts/<contract-id>/projections"
			rootPath: [
				"<contract-id>.root",
				"<contract-id>.projections",
			]
			ownedLeaves: []
		}

		generated: {
			id: "<contract-id>.generated"
			kind: "generated"
			parent: "<contract-id>.root"
			path: "contracts/<contract-id>/generated"
			rootPath: [
				"<contract-id>.root",
				"<contract-id>.generated",
			]
			ownedLeaves: []
		}

		seeds: {
			id: "<contract-id>.seeds"
			kind: "seeds"
			parent: "<contract-id>.root"
			path: "contracts/<contract-id>/seeds"
			rootPath: [
				"<contract-id>.root",
				"<contract-id>.seeds",
			]
			ownedLeaves: []
		}

		workers: {
			id: "<contract-id>.workers"
			kind: "workers"
			parent: "<contract-id>.root"
			path: "contracts/<contract-id>/workers"
			rootPath: [
				"<contract-id>.root",
				"<contract-id>.workers",
			]
			ownedLeaves: []
		}

		checks: {
			id: "<contract-id>.checks"
			kind: "checks"
			parent: "<contract-id>.root"
			path: "contracts/<contract-id>/checks"
			rootPath: [
				"<contract-id>.root",
				"<contract-id>.checks",
			]
			ownedLeaves: []
		}

		hooks: {
			id: "<contract-id>.hooks"
			kind: "hooks"
			parent: "<contract-id>.root"
			path: "contracts/<contract-id>/hooks"
			rootPath: [
				"<contract-id>.root",
				"<contract-id>.hooks",
			]
			ownedLeaves: []
		}
	}

	leaves: {
		// Add concrete leaves only when the slice owns them.
		//
		// Example fixture leaf:
		// "<contract-id>.fixture.lifecycle-positive": {
		// 	kind: "fixture"
		// 	parent: "<contract-id>.fixtures"
		// 	path: "contracts/<contract-id>/fixtures/lifecycle_positive.cue"
		// 	rootPath: [
		// 		"<contract-id>.root",
		// 		"<contract-id>.fixtures",
		// 		"<contract-id>.fixture.lifecycle-positive",
		// 	]
		// }
		//
		// Example check leaf:
		// "<contract-id>.check.lifecycle": {
		// 	kind: "check"
		// 	parent: "<contract-id>.checks"
		// 	path: "contracts/<contract-id>/checks/lifecycle.cue"
		// 	rootPath: [
		// 		"<contract-id>.root",
		// 		"<contract-id>.checks",
		// 		"<contract-id>.check.lifecycle",
		// 	]
		// }
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

	relations: []

	assertions: {
		"<contract-id>.sections-contained": {
			subject: "<contract-id>.root"
			fact: "Every contract section has a declared authority path back to the contract root."
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
			evidence: ["<contract-id>.check.sections-contained"]
			polarity: "invariant"
			strength: "required"
		}

		// Add this only when concrete leaves exist.
		// "<contract-id>.leaves-contained": {
		// 	subject: "<contract-id>.root"
		// 	fact: "Every owned leaf has a declared authority path back to its contract section and root."
		// 	appliesTo: [for _, leaf in leaves {leaf.id}]
		// 	evidence: ["<contract-id>.check.leaves-contained"]
		// 	polarity: "invariant"
		// 	strength: "required"
		// }
	}

	checks: {
		"<contract-id>.check.sections-contained": {
			kind: "cue-vet"
			assertions: ["<contract-id>.sections-contained"]
			target: "<contract-id>.root"
			command: ["cue vet ./contracts/<contract-id>"]
			failure: "Contract domain contains an orphaned, mis-owned, or unproven section."
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
			requiredAssertions: ["<contract-id>.sections-contained"]
			actions: ["inspect", "run_validation", "collect_evidence"]

			// In executable CUE this should be inherited from or checked against
			// agentruntime.#WorkerRequest / #WorkerPolicy instead of redefined.
			pathScope: {
				allowedPaths: ["contracts/<contract-id>"]
				deniedPaths: []
			}
			mayMutate: false
		}
	}

	hooks: {}
}
```

## Migration Checklist

1. Declare the root and sections first.
2. Add concrete leaves only for the slice that owns them.
3. Keep fixture leaves under `sections.fixtures`; keep executable evidence under
   `sections.checks`.
4. Give every section and leaf a `parent` and full `rootPath`.
5. Use `authorityEdges` only for ownership/containment.
6. Use `relations` for `asserts`, `evidences`, `validates`, `derives`,
   `projects`, `guards`, `depends_on`, and `adapts`.
7. Add assertions as contract-owned facts before adding checks.
8. Bind workers through `#WorkerBinding`; do not redefine worker runtime
   request/result/action/budget semantics.
9. Keep shell, hooks, and just recipes as adapters.
10. Keep GitHub issue administration in `issue-admin`; do not mix it into
    contract, fixture, or validation implementation slices.
