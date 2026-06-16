
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
the top-level folder. The real unit is the contract object model.

Example:

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
spread as a single rooted graph.

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

## Intended model

```text
contract object model
  owns rooted graph

rooted graph
  owns branches and leaves

assertions
  declare facts about the graph

checks
  provide executable evidence for assertions

workers
  mutate only within graph/assertion bounds

hooks
  guard mutation boundaries

just/shell
  expose commands, but do not own authority
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
#RootedGraph
#GraphNode
#GraphEdge
#DomainBranch
#Assertion
#Check
#GraphWorker
#HookBoundary
#DomainContract
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

Graph workers should bind to the existing bounded SDK worker contract in
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

  -> agentContextResolver: graph.#DomainContract
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

`agent-context-resolver` is a rooted arborescent domain graph.

The root is `contracts/agent-context-resolver`.

Every owned leaf must have a declared path back to the root through ownership,
derivation, validation, or assertion edges.

Assertions are contract-owned facts about the graph.

Workers are bounded mutators. A worker may inspect or mutate only the graph
nodes allowed by its declared worker contract, and only while preserving the
required assertions.

## Required invariant

No owned leaf may exist without a declared path back to the contract root.

## Required contract additions

- domain graph nodes
- domain graph edges
- assertions as facts
- checks as evidence for facts
- workers as bounded graph mutators
- hook routes as mutation-boundary guards
```

## Generic base layer

Use this as the clean generic base layer. Put it under the existing generic
contract surface, preferably `contracts/graph` or equivalent, then bind dirty
domain packages into it incrementally.

When this moves into `contracts/graph`, preserve the existing exported `df:*`
ID surface or provide compatibility aliases. Current packages already import
that surface.

The root-path invariant must be enforced as reachability from `graph.root`, not
only as local parent-reference validity. A disconnected subtree with valid local
parents is still invalid unless it is explicitly marked as cross-domain or
migration glue.

```cue
package graph

import "list"

// -----------------------------------------------------------------------------
// Scalar interfaces
// -----------------------------------------------------------------------------

#ID: string & =~"^[a-z0-9][a-z0-9._-]*$"

#RelPath: string & !="" & !~"^/" & !~"(^|/)\\.\\.(/|$)"

#SchemaID: string & =~"^[a-z][a-z0-9.-]*\\.v[0-9]+$"

// -----------------------------------------------------------------------------
// Object model interface
// -----------------------------------------------------------------------------

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

// -----------------------------------------------------------------------------
// Rooted graph interface
// -----------------------------------------------------------------------------

#GraphNodeKind:
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

#GraphEdgeKind:
	"owns" |
	"contains" |
	"derives" |
	"projects" |
	"validates" |
	"asserts" |
	"evidences" |
	"executes" |
	"guards" |
	"depends_on" |
	"adapts" |
	"blocks"

#GraphNode: close({
	id:   #ID
	kind: #GraphNodeKind

	// Path is optional because not every graph node is file-backed.
	path?: #RelPath

	// Parent gives the arborescent shape.
	// Root nodes omit parent.
	parent?: #ID

	// Logical branch this node belongs to.
	branch?: #ID

	// Contract object model that owns or defines this node.
	model?: #ID

	description?: string & !=""
})

#GraphEdge: close({
	from: #ID
	to:   #ID
	kind: #GraphEdgeKind

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

#RootedGraph: close({
	id:   #ID
	root: #ID

	nodes:    [string]: #GraphNode
	edges:    [...#GraphEdge]
	branches: [string]: #DomainBranch

	_nodeIDs:   [for id, _ in nodes {id}]
	_branchIDs: [for id, _ in branches {id}]

	if !list.Contains(_nodeIDs, root) {
		_missingRootNode: _|_
	}

	for id, node in nodes {
		node.id: id

		if node.kind != "root" {
			parent: _
		}

		if node.kind == "root" {
			parent?: _|_
		}

		if node.parent != _|_ {
			if !list.Contains(_nodeIDs, node.parent) {
				_unknownParentNode: _|_
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

	for edge in edges {
		if !list.Contains(_nodeIDs, edge.from) {
			_unknownEdgeFromNode: _|_
		}

		if !list.Contains(_nodeIDs, edge.to) {
			_unknownEdgeToNode: _|_
		}
	}
})

// -----------------------------------------------------------------------------
// Assertion interface
// -----------------------------------------------------------------------------

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
	id: #ID

	// Fact asserted by the contract.
	fact: string & !=""

	// Primary graph node the fact is about.
	subject: #ID

	// Nodes the assertion constrains.
	appliesTo: [...#ID]

	// Check, fixture, proof, or generated-evidence node IDs.
	evidence: [...#ID]

	polarity: #AssertionPolarity
	strength: #AssertionStrength | *"required"

	description?: string & !=""
})

// -----------------------------------------------------------------------------
// Check interface
// -----------------------------------------------------------------------------

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

// -----------------------------------------------------------------------------
// Worker interface
// -----------------------------------------------------------------------------

#WorkerKind:
	"projection-worker" |
	"fixture-worker" |
	"validation-worker" |
	"git-worker"

#WorkerAction:
	"inspect" |
	"write_projection" |
	"write_fixture" |
	"mutate_source" |
	"run_validation" |
	"collect_evidence" |
	"inspect_git" |
	"stage" |
	"commit"

#WorkerStopCondition:
	"objective_complete" |
	"command_budget_exhausted" |
	"scope_violation" |
	"validation_failed" |
	"permission_required" |
	"blocked"

#WorkerResultStatus:
	"pass" |
	"fail" |
	"blocked" |
	"stopped"

#WorkerResultAuthority:
	"evidence_only"

#WorkerInputArtifact: close({
	id:   #ID
	kind:
		"contract" |
		"fixture" |
		"projection" |
		"generated" |
		"patch" |
		"route-result" |
		"command-output"

	node?: #ID
	path?: #RelPath
	ref?:  string & !=""
})

#WorkerCommandBudget: close({
	maxCommands: int & >0

	allowedCommands: [string & !="", ...string & !=""]
})

#WorkerExpectedResult: close({
	schema: #SchemaID | "agent.worker-result.v1"

	allowedStatuses: [#WorkerResultStatus, ...#WorkerResultStatus]

	requireValidationEvidence: bool

	maxChangedNodes: int & >=0
	maxChangedPaths: int & >=0
})

#WorkerPermissions: close({
	commit: bool | *false
	stage:  bool | *false
	write:  bool | *false
})

#Worker: close({
	id:   #ID
	kind: #WorkerKind

	objective: string & !=""

	allowedNodes: [#ID, ...#ID]
	deniedNodes:  [...#ID]

	allowedPaths?: [...#RelPath]
	deniedPaths?:  [...#RelPath]

	requiredAssertions: [...#ID]

	inputArtifacts: [...#WorkerInputArtifact]

	actions: [#WorkerAction, ...#WorkerAction]

	commandBudget: #WorkerCommandBudget

	stopConditions: [#WorkerStopCondition, ...#WorkerStopCondition]

	expectedResult: #WorkerExpectedResult

	permissions: #WorkerPermissions

	resultAuthority: #WorkerResultAuthority | *"evidence_only"

	rootAuthority: close({
		planning:    "root_agent"
		merge:       "root_agent"
		retry:       "root_agent"
		scopeChange: "root_agent"
		finalCommit: "root_agent"
	})

	for action in actions {
		if action == "commit" {
			permissions: commit: true
		}
		if action == "stage" {
			permissions: stage: true
		}
		if action == "write_projection" || action == "write_fixture" || action == "mutate_source" {
			permissions: write: true
		}
	}
})

// -----------------------------------------------------------------------------
// Hook boundary interface
// -----------------------------------------------------------------------------

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

// -----------------------------------------------------------------------------
// Domain contract interface
// -----------------------------------------------------------------------------

#DomainContract: close({
	id: #ID

	model: #ObjectModel
	graph: #RootedGraph

	assertions: [string]: #Assertion
	checks:     [string]: #Check
	workers:   [string]: #Worker
	hooks?:     [string]: #HookBoundary

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

		if worker.kind == "validation-worker" {
			for action in worker.actions {
				if action == "write_projection" ||
					action == "write_fixture" ||
					action == "mutate_source" ||
					action == "stage" ||
					action == "commit" {
					_validationWorkerMutationDenied: _|_
				}
			}
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
})
```

## Fold-in order

Use this sequence to bind the dirty layout safely:

1. Add the generic model.
2. Make `contracts/agent-context-resolver` expose one `agentContextResolver: graph.#DomainContract`.
3. Add only graph nodes/edges first.
4. Add assertion facts.
5. Add checks as evidence.
6. Add one `validation-worker`.
7. Add hook boundaries.
8. Only then project `just` recipes and shell adapters.

First resolver instance target:

```cue
agentContextResolver: graph.#DomainContract & {
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
			}
			"agent-context-resolver.fixtures": {
				kind: "fixture"
				path: "fixtures/resolver/agent-context-resolver"
				parent: "agent-context-resolver.root"
			}
			"agent-context-resolver.generated": {
				kind: "generated"
				path: "generated/agent-context-resolver"
				parent: "agent-context-resolver.root"
			}
		}
		edges: [
			{from: "agent-context-resolver.root", to: "agent-context-resolver.fixtures", kind: "owns"},
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
