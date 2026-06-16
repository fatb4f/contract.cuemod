
# Rooted Contract Domain Refactor

## Why we are refactoring

The current contract and validation model is drifting because it treats the
repository's artifact folders as the main work domains:

```text
contracts/
fixtures/
generated/
projections/
providers/
adapters/
seeds/
```

That was the premise of the earlier issue: create child issues for each
top-level source domain such as `adapters`, `contracts`, `fixtures`,
`generated`, `projections`, `providers`, and `seeds`.

That model is wrong for the intended architecture. The real unit of work is not
the top-level folder. The real unit is the `ContractDomain`: an independent
rooted arborescent authority graph owned by one contract package.

Current migration example:

```text
agent-context-resolver
  root: contracts/agent-context-resolver

  leaves:
    fixtures/resolver/agent-context-resolver
    fixtures/resolver/workspace-lifecycle
    generated/agent-context-resolver
    seeds/contract-cuemod/agent-context-resolver
    test/agent-context-hook.sh
```

The refactor is needed because the current layout spreads one functional domain
across many artifact-kind folders, while the contract does not yet declare that
spread as a single rooted graph. The desired end state is a contained contract:
fixtures, checks, hooks, workers, and generated outputs are contract-local
branches instead of repo-wide artifact folders.

## Core problem

The current validation model can answer:

```text
does this file/package/check pass?
```

It cannot yet answer:

```text
why does this leaf exist?
which contract root owns it?
which assertion does it support?
which worker may mutate it?
which hook must guard it?
```

That is the missing authority model.

## What we are refactoring

We are refactoring from:

```text
folder-based validation
  -> glued shell commands
  -> implicit ownership
  -> scattered fixtures/generated/tests
```

To:

```text
contract-rooted object model
  -> rooted graph
  -> declared branches/leaves
  -> assertions as facts
  -> checks as evidence
  -> workers as bounded mutators
  -> just/hooks/shell as adapters
```

## Primary contract ontology

```text
ContractDomain
  = independent rooted arborescent authority graph

root
  = contract package root

owned leaves
  = adapters / fixtures / generated / projections / seeds / hooks / tests

assertions
  = facts declared by the contract

checks
  = executable evidence for assertions

workers
  = bounded mutators over graph nodes, constrained by assertions

hooks / just / shell
  = adapters that enforce or expose contract authority
```

Desired containment shape:

```text
.
root
└── contract
    ├── assertions
    ├── fixtures
    ├── adapters
    ├── projections
    ├── generated
    ├── seeds
    ├── workers
    ├── checks
    └── hooks
```

For a specific domain, `contract` is the contract package root. For
`agent-context-resolver`, that root is `contracts/agent-context-resolver`.

The ownership graph is arborescent. The relation graph can be richer.

```text
ownership edges
  root -> branch -> leaf
  single authority parent
  no orphan leaves

relation edges
  asserts
  evidences
  validates
  derives
  projects
  guards
  depends_on
  adapts
```

So:

```text
contract authority = tree / arborescence
contract semantics = typed graph over that tree
```

## Main invariant

```text
no owned leaf without a declared path back to the contract root
```

For `agent-context-resolver`, every leaf must trace back to:

```text
contracts/agent-context-resolver
```

A generated artifact, fixture, seed, test, or hook script is valid only if the
contract graph says why it exists and how it relates to the root.

If a path cannot trace back to its contract root, then it is one of:

1. orphaned;
2. mis-owned;
3. a cross-domain dependency;
4. temporary migration glue that must be explicitly marked.

## What changes first

1. Add a generic CUE graph base with typed interfaces:

```text
#ObjectModel
#ContractDomain
#AuthorityGraph
#AuthorityNode
#AuthorityEdge
#RelationEdge
#DomainBranch
#Assertion
#Check
#WorkerBinding
#HookBoundary
```

2. Preserve existing `contracts/graph` compatibility.

The existing `contracts/graph` public surface must not be broken. If it already
exposes `df:*` ID types used elsewhere, the new graph model must be additive or
compatibility-preserving.

3. Enforce real root reachability.

Local parent checks are not enough. A disconnected subtree can still have valid
local parents. The model must prove:

```text
every owned node has a transitive path to graph.root
```

The practical CUE approach is to require explicit `rootPath` data per node and
validate it.

4. Bind workers to `agent-runtime`.

The graph model should not duplicate worker semantics.

Wrong:

```text
contracts/graph defines its own worker kinds/actions/budgets
```

Correct:

```text
contracts/graph defines graph-local worker bindings
contracts/agent-runtime owns executable SDK worker semantics
```

`ContractDomain.workers` should declare graph-local worker bindings. Executable
worker mechanics remain owned by `agent-runtime`. Graph workers should bind to
the existing bounded SDK worker contract in
`contracts/agent-runtime/sdk_workers.cue`.

5. Fold in `agent-context-resolver` as the first object model.

Expose one contiguous root object from the existing fragmented CUE package:

```text
contracts/agent-context-resolver
  resolver.cue
  routes.cue
  gates.cue
  hooks.cue
  projection.cue
  fragments.cue
  proof.cue
  registry.cue

  -> agentContextResolver: graph.#ContractDomain
```

During the migration, existing external leaves can be declared with explicit
authority paths. The target shape should then move or project those leaves into
contract-local branches:

```text
contracts/agent-context-resolver
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

Use `docs/refactor/contract-domain-template.md` as the reusable starting point
for each contract migration.

Each `contracts/*` package should define an independent contract domain entity:

```text
contracts/agent-context-resolver
  -> agentContextResolver: graph.#ContractDomain

contracts/agent-runtime
  -> agentRuntime: graph.#ContractDomain

contracts/repo
  -> repo: graph.#ContractDomain

contracts/vcs
  -> vcs: graph.#ContractDomain
```

The repo-wide registry indexes these domains. It must not collapse them into one
mega-tree:

```text
contracts/registry.cue
  = catalogue of contract roots
  = cross-contract reference table
  != owner of every leaf
```

## What this is not

This is not primarily:

```text
clean up shell scripts
add more tests
move files around
split by top-level folders
```

Those are secondary. The actual refactor is:

```text
make the contract declare the object model graph
```

Once that exists, validation, hooks, just recipes, fixtures, generated
freshness, and worker permissions can all be derived or checked against the same
authority surface.

One-sentence summary: the repository currently validates scattered artifacts,
but the intended architecture needs each `contracts/*` package to declare a
rooted object model where every leaf, assertion, check, worker, and hook has an
explicit path back to contract authority.

## Issue wording

Use this wording for the issue and child implementation slices:

```md
## Model

Each contract in `contract.cuemod` is an independent arborescent graph entity.

The contract package is the root. Every assertion, adapter, fixture, generated
artifact, projection, seed, hook, check, and worker binding owned by that
contract must be contained under that contract root or explicitly marked as
migration glue with a declared authority path back to the root.

Ownership is arborescent: each owned node has one authority parent, except the
root.

Typed relation edges may form a richer graph over the owned tree:

- asserts
- evidences
- validates
- derives
- projects
- guards
- depends_on
- adapts

Assertions are contract-owned facts about the graph.

Checks are executable evidence for assertions.

Workers are bounded mutators. A worker may inspect or mutate only the nodes
allowed by its declared worker binding, and only while preserving the required
assertions.

The repo registry indexes independent contract domains. It does not become a
mega-owner of every leaf.

## Required invariant

No owned leaf may exist without a declared authority path back to the contract
root.
```

## Generic base layer

Use this as the clean generic base layer. Put it under the existing generic
contract surface, preferably `contracts/graph` or equivalent, then bind dirty
domain packages into it incrementally.

When this moves into `contracts/graph`, preserve the existing exported `df:*`
ID surface or provide compatibility aliases. Current packages already import
that surface.

The target generic layer uses `#ContractDomain` as the primary primitive, with
an owned `#AuthorityGraph` for arborescent authority and typed relation edges
over that authority tree.

The root-path invariant must be enforced as reachability from `graph.root`, not
only as local parent-reference validity. A disconnected subtree with valid local
parents is still invalid unless it is explicitly marked as cross-domain or
migration glue. The intended hard invariant is:

```text
For every owned node N:

1. N.rootPath[0] == graph.root
2. N.rootPath[-1] == N.id
3. every adjacent pair in rootPath is connected by an ownership edge
4. N has exactly one authority parent, except root
5. no file-backed owned leaf exists outside this tree
```

Worker semantics should not be duplicated here. `contracts/graph` defines
graph-local worker bindings; `contracts/agent-runtime/sdk_workers.cue` owns
worker request/result/action/budget semantics.

```cue
package graph

import (
	"list"

	agentruntime "github.com/fatb4f/contract.cuemod/contracts/agent-runtime"
)

#ID: string & =~"^[a-z0-9][a-z0-9._-]*$"

#RelPath: string & !="" & !~"^/" & !~"(^|/)\\.\\.(/|$)"

#SchemaID: string & =~"^[a-z][a-z0-9.-]*\\.v[0-9]+$"

#Fact: string & !=""

#ObjectModelKind:
	"contract-object-model" |
	"functional-domain" |
	"artifact-domain" |
	"adapter-domain" |
	"projection-domain"

#ObjectModel: close({
	id:       #ID
	kind:     #ObjectModelKind
	package:  string & !=""
	rootPath: #RelPath

	description?: string & !=""

	definitions?: [string]: #DefinitionRef
	exports?:     [string]: #ExportRef
})

#DefinitionRef: close({
	name: string & =~"^#"
	role:
		"root" |
		"entity" |
		"value-object" |
		"assertion" |
		"worker" |
		"projection" |
		"fixture" |
		"adapter" |
		"hook"
})

#ExportRef: close({
	expr: string & !=""
	kind:
		"model" |
		"projection" |
		"inventory" |
		"manifest" |
		"fixture" |
		"check"
	concrete: bool
})

#NodeKind:
	"root" |
	"object-model" |
	"contract" |
	"branch" |
	"assertion" |
	"worker" |
	"check" |
	"fixture" |
	"generated" |
	"projection" |
	"provider" |
	"adapter" |
	"seed" |
	"test" |
	"hook" |
	"external"

#AuthorityEdgeKind:
	"owns" |
	"contains"

#RelationEdgeKind:
	"asserts" |
	"evidences" |
	"validates" |
	"derives" |
	"projects" |
	"executes" |
	"guards" |
	"depends_on" |
	"adapts" |
	"blocks"

#AuthorityNode: close({
	id:   #ID
	kind: #NodeKind

	// Path is optional because not every graph node is file-backed.
	path?: #RelPath

	// Parent gives the arborescent shape.
	// Root nodes omit parent.
	parent?: #ID

	// Explicit authority path from graph root to this node.
	rootPath: [#ID, ...#ID]

	// Logical branch this node belongs to.
	branch?: #ID

	// Contract object model that owns or defines this node.
	model?: #ID

	description?: string & !=""
})

#AuthorityEdge: close({
	from: #ID
	to:   #ID
	kind: #AuthorityEdgeKind
})

#RelationEdge: close({
	from: #ID
	to:   #ID
	kind: #RelationEdgeKind

	description?: string & !=""
})

#DomainBranchKind:
	"authority" |
	"contract" |
	"fixture" |
	"generated" |
	"projection" |
	"provider" |
	"adapter" |
	"seed" |
	"test" |
	"hook" |
	"worker" |
	"external"

#DomainBranch: close({
	id:   #ID
	kind: #DomainBranchKind

	rootNode: #ID

	parentBranch?: #ID
	pathPrefix?:   #RelPath

	description?: string & !=""

	ownedNodes: [...#ID]
})

#AuthorityGraph: close({
	id:   #ID
	root: #ID

	nodes:          [string]: #AuthorityNode
	authorityEdges: [...#AuthorityEdge]
	relationEdges:  [...#RelationEdge]
	branches:       [string]: #DomainBranch

	_nodeIDs:   [for id, _ in nodes {id}]
	_branchIDs: [for id, _ in branches {id}]
	_authorityPairs: [for edge in authorityEdges {"\(edge.from)|\(edge.to)"}]

	if !list.Contains(_nodeIDs, root) {
		_missingRootNode: _|_
	}

	for id, node in nodes {
		node.id: id

		if id == root {
			node.kind: "root"
			node.parent?: _|_
			node.rootPath: [root]
		}

		if id != root {
			node.parent: _
			node.rootPath[0]: root
			node.rootPath[len(node.rootPath)-1]: id
		}

		if id != root {
			if !list.Contains(_nodeIDs, node.parent) {
				_unknownParentNode: _|_
			}
			if !list.Contains(_authorityPairs, "\(node.parent)|\(id)") {
				_missingAuthorityEdge: _|_
			}
		}

		for i, nodeID in node.rootPath {
			if !list.Contains(_nodeIDs, nodeID) {
				_unknownRootPathNode: _|_
			}
			if i > 0 {
				if !list.Contains(_authorityPairs, "\(node.rootPath[i-1])|\(nodeID)") {
					_missingRootPathAuthorityEdge: _|_
				}
			}
		}

		if node.branch != _|_ {
			if !list.Contains(_branchIDs, node.branch) {
				_unknownNodeBranch: _|_
			}
		}
	}

	for id, branch in branches {
		branch.id: id

		if !list.Contains(_nodeIDs, branch.rootNode) {
			_unknownBranchRoot: _|_
		}

		if branch.parentBranch != _|_ {
			if !list.Contains(_branchIDs, branch.parentBranch) {
				_unknownParentBranch: _|_
			}
		}

		for nodeID in branch.ownedNodes {
			if !list.Contains(_nodeIDs, nodeID) {
				_unknownBranchNode: _|_
			}
		}
	}

	for edge in authorityEdges {
		if !list.Contains(_nodeIDs, edge.from) {
			_unknownAuthorityEdgeFromNode: _|_
		}

		if !list.Contains(_nodeIDs, edge.to) {
			_unknownAuthorityEdgeToNode: _|_
		}
	}

	for edge in relationEdges {
		if !list.Contains(_nodeIDs, edge.from) {
			_unknownRelationEdgeFromNode: _|_
		}

		if !list.Contains(_nodeIDs, edge.to) {
			_unknownRelationEdgeToNode: _|_
		}
	}
})

#AssertionPolarity:
	"positive" |
	"negative" |
	"invariant"

#AssertionStrength:
	"required" |
	"recommended" |
	"temporary" |
	"migration"

#Assertion: close({
	id:      #ID
	subject: #ID
	fact:    #Fact

	appliesTo: [...#ID]

	// Check IDs that provide executable evidence for this fact.
	evidence: [...#ID]

	polarity: #AssertionPolarity
	strength: #AssertionStrength | *"required"
	status:   "active" | "deprecated" | "planned" | *"active"

	description?: string & !=""
})

#CheckKind:
	"cue-vet" |
	"cue-export" |
	"cue-def" |
	"shell" |
	"negative-cue-vet" |
	"fixture-polarity" |
	"generated-freshness" |
	"hook-regression" |
	"worker-result"

#CheckExpectation:
	"pass" |
	"fail"

#Check: close({
	id:   #ID
	kind: #CheckKind

	// Assertions this check provides evidence for.
	assertions: [#ID, ...#ID]

	// Node this check validates.
	target: #ID

	expect: #CheckExpectation | *"pass"

	command?: [...string & !=""]
	path?:    #RelPath
	expr?:    string & !=""

	failure: string & !=""
})

#WorkerBinding: close({
	id:   #ID
	kind: agentruntime.#SDKWorkerKind

	objective: string & !=""

	allowedNodes: [#ID, ...#ID]
	deniedNodes:  [...#ID]

	allowedPaths?: [...#RelPath]
	deniedPaths?:  [...#RelPath]

	requiredAssertions: [...#ID]

	pathScope?: agentruntime.#WorkerPathScope
	actions:    [agentruntime.#WorkerAction, ...agentruntime.#WorkerAction]

	mayMutate:   bool | *false
	mayGenerate: bool | *false
	mayStage:    bool | *false
	mayCommit:   bool | *false

	resultAuthority: "evidence_only" | *"evidence_only"
})

#HookKind:
	"pre-commit" |
	"pre-tool-use" |
	"post-tool-use" |
	"manual"

#HookBoundary: close({
	id:   #ID
	kind: #HookKind

	guardsNodes: [...#ID]
	guardsPaths: [...#RelPath]

	requiredAssertions: [...#ID]

	worker: #ID

	onFailure:
		"block" |
		"warn" |
		"report"

	description?: string & !=""
})

#OwnedAdapter: close({
	node: #ID
})

#OwnedFixture: close({
	node: #ID
})

#OwnedProjection: close({
	node: #ID
})

#OwnedGenerated: close({
	node: #ID
})

#OwnedSeed: close({
	node: #ID
})

#ContractDomain: close({
	id: #ID

	model: #ObjectModel
	graph: #AuthorityGraph

	assertions: [string]: #Assertion
	checks:     [string]: #Check
	workers:   [string]: #WorkerBinding
	hooks?:     [string]: #HookBoundary

	adapters:    [string]: #OwnedAdapter
	fixtures:    [string]: #OwnedFixture
	projections: [string]: #OwnedProjection
	generated:   [string]: #OwnedGenerated
	seeds:       [string]: #OwnedSeed

	_nodeIDs:      [for id, _ in graph.nodes {id}]
	_assertionIDs: [for id, _ in assertions {id}]
	_checkIDs:     [for id, _ in checks {id}]
	_workerIDs:    [for id, _ in workers {id}]
	_hookIDs:      [for id, _ in hooks {id}]

	model.id: id
	graph.id: id

	for id, assertion in assertions {
		assertion.id: id

		if !list.Contains(_nodeIDs, assertion.subject) {
			_unknownAssertionSubject: _|_
		}

		for nodeID in assertion.appliesTo {
			if !list.Contains(_nodeIDs, nodeID) {
				_unknownAssertionNode: _|_
			}
		}

		for evidenceID in assertion.evidence {
			if !list.Contains(_nodeIDs, evidenceID) && !list.Contains(_checkIDs, evidenceID) {
				_unknownAssertionEvidence: _|_
			}
		}
	}

	for id, check in checks {
		check.id: id

		if !list.Contains(_nodeIDs, check.target) {
			_unknownCheckTarget: _|_
		}

		for assertionID in check.assertions {
			if !list.Contains(_assertionIDs, assertionID) {
				_unknownCheckAssertion: _|_
			}
		}
	}

	for id, worker in workers {
		worker.id: id

		for nodeID in worker.allowedNodes {
			if !list.Contains(_nodeIDs, nodeID) {
				_unknownWorkerAllowedNode: _|_
			}
		}

		for nodeID in worker.deniedNodes {
			if !list.Contains(_nodeIDs, nodeID) {
				_unknownWorkerDeniedNode: _|_
			}
		}

		for assertionID in worker.requiredAssertions {
			if !list.Contains(_assertionIDs, assertionID) {
				_unknownWorkerAssertion: _|_
			}
		}

		if worker.kind == "validation-worker" && worker.mayMutate {
			_validationWorkerMutationDenied: _|_
		}
	}

	for id, hook in hooks {
		hook.id: id

		if !list.Contains(_workerIDs, hook.worker) {
			_unknownHookWorker: _|_
		}

		for nodeID in hook.guardsNodes {
			if !list.Contains(_nodeIDs, nodeID) {
				_unknownHookGuardNode: _|_
			}
		}

		for assertionID in hook.requiredAssertions {
			if !list.Contains(_assertionIDs, assertionID) {
				_unknownHookAssertion: _|_
			}
		}
	}

	for _, owned in adapters {
		if !list.Contains(_nodeIDs, owned.node) {
			_unknownOwnedAdapterNode: _|_
		}
	}
	for _, owned in fixtures {
		if !list.Contains(_nodeIDs, owned.node) {
			_unknownOwnedFixtureNode: _|_
		}
	}
	for _, owned in projections {
		if !list.Contains(_nodeIDs, owned.node) {
			_unknownOwnedProjectionNode: _|_
		}
	}
	for _, owned in generated {
		if !list.Contains(_nodeIDs, owned.node) {
			_unknownOwnedGeneratedNode: _|_
		}
	}
	for _, owned in seeds {
		if !list.Contains(_nodeIDs, owned.node) {
			_unknownOwnedSeedNode: _|_
		}
	}
})
```

## Fold-in order

Use this sequence to bind the dirty layout safely:

1. Add the generic model.
2. Make `contracts/agent-context-resolver` expose one `agentContextResolver: graph.#ContractDomain`.
3. Add only graph nodes/edges first.
4. Add assertion facts.
5. Add checks as evidence.
6. Add one `validation-worker`.
7. Add hook boundaries.
8. Only then project `just` recipes and shell adapters.

First resolver instance target:

```cue
agentContextResolver: graph.#ContractDomain & {
	id: "agent-context-resolver"

	model: {
		id: "agent-context-resolver"
		kind: "functional-domain"
		package: "agentcontextresolver"
		rootPath: "contracts/agent-context-resolver"
	}

	graph: {
		root: "agent-context-resolver.root"
		nodes: {
			"agent-context-resolver.root": {
				kind: "root"
				path: "contracts/agent-context-resolver"
				rootPath: ["agent-context-resolver.root"]
			}
			"agent-context-resolver.fixtures": {
				kind: "fixture"
				path: "fixtures/resolver/agent-context-resolver"
				parent: "agent-context-resolver.root"
				rootPath: [
					"agent-context-resolver.root",
					"agent-context-resolver.fixtures",
				]
			}
			"agent-context-resolver.generated": {
				kind: "generated"
				path: "generated/agent-context-resolver"
				parent: "agent-context-resolver.root"
				rootPath: [
					"agent-context-resolver.root",
					"agent-context-resolver.generated",
				]
			}
		}
		authorityEdges: [
			{from: "agent-context-resolver.root", to: "agent-context-resolver.fixtures", kind: "owns"},
			{from: "agent-context-resolver.root", to: "agent-context-resolver.generated", kind: "owns"},
		]
		relationEdges: [
			{from: "agent-context-resolver.root", to: "agent-context-resolver.generated", kind: "derives"},
		]
		branches: {}
	}

	assertions: {}
	checks: {}
	workers: {}
	hooks: {}
}
```

The clean base lets the dirty layout fold inward without moving files or making `test/check.sh` the authority.
