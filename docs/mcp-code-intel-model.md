# MCP Code-Intel Surface Model — v0

## 0. Core decision

**Do not model “MCP server = code intelligence.”**

Model it as:

```text
Contract Graph
  → Code-Intel Domain Model
    → Control Surface
      → MCP Projection
        → Adapters
```

MCP is the **protocol projection layer**. The actual authority should remain a typed CUE/JSON contract graph.

MCP gives us JSON-RPC transport, lifecycle/capability negotiation, and protocol primitives for resources, prompts, tools, sampling, roots, and elicitation. The spec defines hosts, clients, and servers, with servers providing context/capabilities to clients and hosts initiating connections. citeturn865407view3

---

# 1. Contract spine

Every modeled object gets the same minimum envelope:

```cue
#Rationale: {
	why:        string
	problem:    string
	nonGoals?: [...string]
	tradeoffs?: [...string]
}

#Contract: {
	inputs:       [...#Port]
	outputs:      [...#Port]
	preconditions: [...string]
	postconditions: [...string]
	invariants:    [...string]
	failureModes:  [...#FailureMode]
	authz:         #Authz
	evidence:      [...#EvidenceRef]
}

#Component: {
	id:        string
	kind:      "component" | "adapter" | "interface" | "workflow" | "resource" | "tool"
	rationale: #Rationale
	contract:  #Contract
}
```

**Rule:** no component, adapter, or interface exists without:

```text
id
kind
rationale
contract
capability surface
failure semantics
evidence link
```

---

# 2. Control-theoretic model

The codebase/toolchain is the **plant**. The agent/controller observes it through sensors, estimates state, chooses actions, invokes actuators, and validates feedback.

```text
reference objective r
        ↓
 controller / planner C
        ↓ command u
 code-intel actuators A
        ↓
 repo + toolchains + FS + LSPs = plant P
        ↓ observation y
 sensors / adapters S
        ↓
 state estimator E
        ↓ estimated state x̂
        ↺ feedback to controller
```

Objective sketch:

genui{"math_block_widget_always_prefetch_v2":{"content":"J = \\alpha U + \\beta V + \\gamma C + \\delta R - \\lambda E"}}

Where:

| Term | Meaning |
|---|---|
| `U` | uncertainty: unresolved symbols, missing contracts, unknown files |
| `V` | violations: diagnostics, schema failures, policy breaches |
| `C` | cost: latency, tokens, tool calls, index rebuilds |
| `R` | risk: write scope, unsafe command, stale cache, prompt injection |
| `E` | evidence quality: reproducible facts, typed symbols, test output |

The controller should minimize uncertainty, violations, cost, and risk while maximizing evidence.

---

# 3. Domain state model

```cue
#CodeIntelState: {
	workspace:     #WorkspaceState
	filesystem:    #VFSState
	languages:     [...#LanguageState]
	symbolGraph:   #SymbolGraph
	dependencyGraph: #DependencyGraph
	diagnostics:   [...#Diagnostic]
	indexes:        [...#IndexState]
	workflows:      [...#WorkflowState]
	policy:         #PolicyState
	evidence:       [...#Evidence]
}
```

## State categories

| State | Meaning |
|---|---|
| `WorkspaceState` | roots, repo identity, git state, project manifests |
| `VFSState` | addressable read model over files, generated files, virtual docs |
| `LanguageState` | LSP server state, parser state, compiler/checker availability |
| `SymbolGraph` | definitions, references, exports, imports, type symbols |
| `DependencyGraph` | packages, modules, import edges, build/test units |
| `DiagnosticSet` | LSP/compiler/parser/test diagnostics |
| `WorkflowState` | active task, phase, decisions, pending evidence |
| `PolicyState` | permissions, write gates, trust zones |
| `EvidenceLedger` | source-backed facts, tool outputs, validation results |

---

# 4. MCP projection

MCP server features map cleanly to this surface:

| MCP primitive | Code-intel role | Control meaning |
|---|---|---|
| **Resources** | read-only context: files, symbols, diagnostics, graphs, indexes | sensors/read model |
| **Tools** | bounded actions: query, inspect, validate, refactor, materialize | actuators |
| **Prompts** | reusable workflows: review, explain, plan, migrate | reference commands |
| **Roots** | workspace/project boundaries from client | operating envelope |
| **Elicitation** | request missing user constraints | external reference input |
| **Sampling** | optional nested LLM operation requested by server | delegated controller step |

MCP resources are specifically for exposing context/data via URIs, and tools are invokable functions exposed by servers. Prompts are templates/workflows intended to be discovered and explicitly selected by users. citeturn327948view3 citeturn327948view2 citeturn865407view0

---

# 5. Component matrix

## 5.1 MCP Server Facade

| Field | Contract |
|---|---|
| **Rationale** | Presents one stable agent-facing surface while hiding LSP/parser/index/toolchain heterogeneity. |
| **Inputs** | MCP requests: `resources/list`, `resources/read`, `tools/call`, `prompts/get`. |
| **Outputs** | Typed JSON responses, errors, progress events, resource URIs. |
| **Invariants** | Never expose uncontracted tools. Never mutate workspace except through write-gated tools. |
| **Failure modes** | unknown capability, bad schema, stale adapter, unauthorized operation. |
| **Evidence** | protocol logs, capability manifest, schema validation output. |

---

## 5.2 Capability Registry

| Field | Contract |
|---|---|
| **Rationale** | Makes available operations explicit, typed, inspectable, and negotiable. |
| **Inputs** | component contracts, adapter manifests, policy rules. |
| **Outputs** | MCP tool/resource/prompt declarations. |
| **Invariants** | Every declared capability must resolve to an implementation and contract. |
| **Failure modes** | dangling capability, duplicate name, schema mismatch. |
| **Evidence** | generated MCP manifest, CUE validation, adapter test. |

---

## 5.3 Workspace / Root Adapter

| Field | Contract |
|---|---|
| **Rationale** | Defines the operational envelope: repo, project, package, roots, ignore policy. |
| **Inputs** | client roots, cwd, git metadata, project manifests. |
| **Outputs** | normalized workspace model. |
| **Invariants** | All file operations must resolve through normalized workspace scope. |
| **Failure modes** | ambiguous root, repo not found, symlink escape, stale cwd. |
| **Evidence** | root list, git top-level, manifest detection output. |

MCP roots let clients expose filesystem boundaries to servers and can notify when roots change; the server still needs its own validation and access policy. citeturn177671view0

---

## 5.4 VFS Adapter

| Field | Contract |
|---|---|
| **Rationale** | Gives the agent addressability over physical files, generated files, virtual docs, and projected artifacts. |
| **Inputs** | workspace roots, file paths, generated artifact refs, overlay state. |
| **Outputs** | `codeintel://file/...`, `codeintel://virtual/...`, `codeintel://generated/...`. |
| **Invariants** | URI identity is stable. Reads are deterministic for a given snapshot. |
| **Failure modes** | missing file, invalid URI, snapshot mismatch, unsupported scheme. |
| **Evidence** | content hash, mtime, git blob hash, generator provenance. |

---

## 5.5 LSP Adapter

| Field | Contract |
|---|---|
| **Rationale** | Reuses language-native intelligence: definitions, references, diagnostics, hover, completion. |
| **Inputs** | normalized workspace, file URI, language server config. |
| **Outputs** | symbols, diagnostics, hover docs, definitions, references. |
| **Invariants** | LSP results must be tagged with server identity, version, file snapshot. |
| **Failure modes** | server unavailable, partial result, stale diagnostics, unsupported method. |
| **Evidence** | LSP request/response trace, server version, diagnostic payload. |

---

## 5.6 Parser Adapter

| Field | Contract |
|---|---|
| **Rationale** | Provides fast structural facts independent of LSP availability. |
| **Inputs** | file content, parser grammar, language id. |
| **Outputs** | AST, syntax errors, node ranges, structural symbols. |
| **Invariants** | Parser output must be snapshot-scoped. |
| **Failure modes** | grammar missing, parse error, encoding issue. |
| **Evidence** | parser version, AST hash, syntax diagnostic set. |

---

## 5.7 Type-System Adapter

| Field | Contract |
|---|---|
| **Rationale** | Captures type authority separately from syntax and symbol lookup. |
| **Inputs** | source files, compiler/LSP/checker config. |
| **Outputs** | inferred types, declared types, type errors, exported API model. |
| **Invariants** | Type facts must record authority: compiler, LSP, annotation, generated schema. |
| **Failure modes** | checker unavailable, incomplete project graph, type fallback only. |
| **Evidence** | checker command, diagnostic output, typed symbol refs. |

For this project, this means at least:

```text
CUE type authority
LuaLS type authority
chezmoi/template type adapter
optional Go/TS authority later
```

---

## 5.8 Resolver Adapter

| Field | Contract |
|---|---|
| **Rationale** | Resolves imports, modules, packages, generated files, and project-local namespaces. |
| **Inputs** | dependency graph, language config, workspace model. |
| **Outputs** | resolved symbols, import edges, package identity, unresolved refs. |
| **Invariants** | Resolution must distinguish “not found” from “not loaded.” |
| **Failure modes** | cyclic import, missing dependency, generated source absent, ambiguous module. |
| **Evidence** | resolver trace, import graph, unresolved-symbol report. |

---

## 5.9 Semantic Index Adapter

| Field | Contract |
|---|---|
| **Rationale** | Allows cheap lookup without repeatedly interrogating LSPs/parsers. |
| **Inputs** | parser facts, LSP facts, type facts, git snapshots. |
| **Outputs** | indexed symbols, references, packages, diagnostics, embeddings if enabled. |
| **Invariants** | Index entries must be invalidated by content hash or dependency hash. |
| **Failure modes** | stale index, partial index, corrupt cache. |
| **Evidence** | index build manifest, hash keys, invalidation logs. |

---

## 5.10 Symbol Graph

| Field | Contract |
|---|---|
| **Rationale** | Provides the relational model agents actually need: “what is this, where used, who owns it, what depends on it?” |
| **Inputs** | LSP symbols, parser symbols, resolver edges, type facts. |
| **Outputs** | graph nodes and edges. |
| **Invariants** | Every symbol node must have source span, authority, and confidence. |
| **Failure modes** | duplicate symbol, unresolved edge, conflicting authority. |
| **Evidence** | source location, authority source, graph build report. |

Example edge types:

```text
defines
references
imports
exports
implements
generates
validates
depends_on
materializes
owned_by
```

---

## 5.11 Diagnostic Aggregator

| Field | Contract |
|---|---|
| **Rationale** | Normalizes diagnostics from LSPs, compilers, CUE validators, parsers, tests, and policy checks. |
| **Inputs** | diagnostic streams from adapters. |
| **Outputs** | normalized diagnostic set. |
| **Invariants** | Diagnostics must preserve original source, severity, span, and tool identity. |
| **Failure modes** | duplicate diagnostics, incompatible severity, missing span. |
| **Evidence** | original diagnostic payload, normalized record. |

---

## 5.12 Workflow Engine

| Field | Contract |
|---|---|
| **Rationale** | Turns raw code-intel operations into repeatable agent workflows. |
| **Inputs** | objective, current state, available tools, policy. |
| **Outputs** | workflow phases, tool calls, evidence, terminal state. |
| **Invariants** | Each workflow phase must declare entry criteria, exit criteria, and rollback semantics. |
| **Failure modes** | blocked by policy, insufficient evidence, irreducible ambiguity. |
| **Evidence** | workflow trace, phase records, final validation report. |

---

## 5.13 Policy / Consent Gate

| Field | Contract |
|---|---|
| **Rationale** | Prevents the MCP surface from becoming uncontrolled arbitrary code execution. |
| **Inputs** | tool request, workspace scope, user policy, risk class. |
| **Outputs** | allow, deny, require confirmation, require elicitation. |
| **Invariants** | Writes, shell execution, network access, and credential access require explicit policy. |
| **Failure modes** | missing policy, denied action, insufficient scope. |
| **Evidence** | policy decision record, user approval record. |

MCP itself emphasizes consent, privacy, and tool safety; its spec notes that tools can represent arbitrary code execution and should be treated cautiously. citeturn865407view4

---

## 5.14 Evidence Ledger

| Field | Contract |
|---|---|
| **Rationale** | Makes agent conclusions auditable instead of conversational. |
| **Inputs** | tool outputs, file hashes, diagnostics, command results, source refs. |
| **Outputs** | evidence records linked to components, workflows, and claims. |
| **Invariants** | No claim should be promoted to “verified” without evidence. |
| **Failure modes** | stale evidence, unverifiable claim, missing provenance. |
| **Evidence** | self-referential: evidence records include source, time, hash, authority. |

---

# 6. Interface taxonomy

## 6.1 Read interfaces

```text
codeintel.workspace.describe
codeintel.vfs.read
codeintel.symbol.lookup
codeintel.symbol.references
codeintel.diagnostics.list
codeintel.graph.query
codeintel.evidence.get
```

**Contract class:** safe, read-only, cacheable.

---

## 6.2 Analysis interfaces

```text
codeintel.parse.file
codeintel.lsp.hover
codeintel.lsp.definition
codeintel.resolve.imports
codeintel.types.infer
codeintel.contract.validate
```

**Contract class:** read-only but potentially expensive.

---

## 6.3 Planning interfaces

```text
codeintel.workflow.plan
codeintel.refactor.plan
codeintel.adapter.plan
codeintel.contract.diff
```

**Contract class:** no mutation; produces proposed actions and required evidence.

---

## 6.4 Mutation interfaces

```text
codeintel.patch.propose
codeintel.patch.apply
codeintel.generated.materialize
codeintel.config.update
```

**Contract class:** write-gated, reversible where possible, evidence-required.

---

## 6.5 Validation interfaces

```text
codeintel.validate.cue
codeintel.validate.lua
codeintel.validate.lsp
codeintel.validate.tests
codeintel.validate.contracts
```

**Contract class:** objective feedback loop.

---

# 7. Workflow model

```cue
#Workflow: {
	id: string
	objective: #Objective

	phases: [...{
		id: string
		rationale: #Rationale
		entry: [...string]
		actions: [...#ToolCallSpec]
		exit: [...string]
		evidence: [...#EvidenceRef]
		rollback?: [...#ToolCallSpec]
	}]

	terminalStates: {
		success: [...string]
		blocked: [...string]
		failed: [...string]
	}
}
```

## Canonical workflow phases

| Phase | Purpose | Control role |
|---|---|---|
| `observe` | gather workspace/symbol/diagnostic state | sensing |
| `estimate` | build current model | state estimation |
| `compare` | compare actual vs target contract | error signal |
| `plan` | select low-risk action sequence | controller |
| `act` | invoke bounded tools | actuator |
| `validate` | run checks and collect evidence | feedback |
| `materialize` | persist generated artifacts | controlled mutation |
| `ledger` | record evidence and decisions | observability |

---

# 8. Objective model

```cue
#Objective: {
	id: string
	target: string

	minimize: {
		uncertainty: bool | *true
		violations:  bool | *true
		cost:        bool | *true
		risk:        bool | *true
	}

	maximize: {
		evidence:       bool | *true
		reproducibility: bool | *true
		locality:       bool | *true
		typeCoverage:   bool | *true
	}

	constraints: [...#Constraint]
	success:     [...string]
}
```

## Initial objectives

| Objective | Success condition |
|---|---|
| `bounded-code-intel` | agent can query codebase without broad shell/file access |
| `typed-contract-surface` | every MCP tool/resource maps to CUE contract |
| `adapter-transparency` | every adapter declares authority, failure modes, and confidence |
| `workflow-replayability` | workflow trace can be replayed from evidence |
| `safe-materialization` | generated files require contract validation before write |
| `multi-language-core` | CUE + LuaLS first; Go/TS optional later |
| `context-budget-control` | expose compact graph/resource views instead of dumping files |

---

# 9. MCP resource namespace

```text
codeintel://workspace/current
codeintel://workspace/roots
codeintel://vfs/file/{path}
codeintel://vfs/generated/{artifact}
codeintel://symbols/{language}/{symbolId}
codeintel://diagnostics/{scope}
codeintel://graph/symbols
codeintel://graph/dependencies
codeintel://contracts/components
codeintel://contracts/adapters
codeintel://evidence/{evidenceId}
codeintel://workflow/{workflowId}
```

Each resource contract should include:

```cue
#ResourceContract: {
	uri: string
	readModel: string
	snapshotScoped: bool
	cacheable: bool
	authz: #Authz
	produces: #SchemaRef
	rationale: #Rationale
}
```

---

# 10. MCP tool namespace

```text
codeintel.workspace.describe
codeintel.vfs.read
codeintel.symbol.lookup
codeintel.symbol.references
codeintel.diagnostics.list
codeintel.graph.query

codeintel.lsp.request
codeintel.parser.parse
codeintel.resolver.resolve
codeintel.types.inspect

codeintel.contract.validate
codeintel.workflow.plan
codeintel.workflow.runPhase
codeintel.patch.propose
codeintel.patch.apply
```

Each tool contract should include:

```cue
#ToolContract: {
	name: string
	risk: "read" | "analysis" | "write" | "exec" | "network"
	inputSchema: #SchemaRef
	outputSchema: #SchemaRef
	preconditions: [...string]
	postconditions: [...string]
	sideEffects: [...string]
	requiresApproval: bool
	timeoutMs: int
	idempotent: bool
	rationale: #Rationale
}
```

MCP tools are model-invokable functions with schemas, so this contract layer is where we prevent “random tool soup.” citeturn327948view2

---

# 11. Prompt/workflow projection

Prompts should not be “magic instructions.” They should be named workflow entrypoints:

```text
/codeintel-review-contract
/codeintel-map-adapter
/codeintel-explain-symbol
/codeintel-plan-refactor
/codeintel-validate-generated
/codeintel-bootstrap-language-surface
```

Each prompt maps to:

```cue
#PromptProjection: {
	name: string
	workflow: #WorkflowRef
	requiredInputs: [...#Port]
	allowedTools: [...string]
	disallowedTools: [...string]
	rationale: #Rationale
}
```

Prompts are user-controlled MCP artifacts intended to expose reusable prompt templates/workflows for explicit selection. citeturn865407view0

---

# 12. Adapter contract pattern

Every adapter should follow this shape:

```cue
#Adapter: #Component & {
	kind: "adapter"

	authority: {
		source: "lsp" | "parser" | "compiler" | "cue" | "git" | "filesystem" | "generated"
		confidence: "authoritative" | "derived" | "heuristic" | "fallback"
	}

	capabilities: [...{
		name: string
		method: string
		input: #SchemaRef
		output: #SchemaRef
	}]

	health: {
		check: string
		expected: [...string]
	}

	cache: {
		enabled: bool
		invalidation: [...string]
	}
}
```

## Adapter examples

| Adapter | Authority | Rationale |
|---|---|---|
| `adapter.cue` | authoritative schema/contract authority | owns contract validation |
| `adapter.lua_ls` | Lua type/symbol authority | exposes WezTerm/Neovim Lua surface |
| `adapter.tree_sitter` | structural parser authority | cheap AST and syntax fallback |
| `adapter.git` | version/history authority | snapshot, diff, evidence, rollback |
| `adapter.chezmoi` | materialization authority | maps source templates to target filesystem |
| `adapter.vfs` | addressability authority | unifies real/virtual/generated files |
| `adapter.test_runner` | behavioral validation authority | verifies effects after changes |

---

# 13. Minimal CUE package layout

```text
contract/
  mcp/
    schema.cue          # MCP projection types
    resources.cue       # resource contracts
    tools.cue           # tool contracts
    prompts.cue         # prompt/workflow projections

  codeintel/
    state.cue           # CodeIntelState
    component.cue       # Component/Rationale/Contract
    adapter.cue         # Adapter contract
    graph.cue           # Symbol/dependency graph
    diagnostic.cue      # normalized diagnostics
    evidence.cue        # evidence ledger

  control/
    objective.cue       # objective/cost/constraints
    workflow.cue        # workflow phase model
    policy.cue          # authz, write gates, risk model

  languages/
    cue.cue
    lua.cue
    go.cue
    typescript.cue

  projections/
    mcp_server.cue      # generated MCP manifest
    docs.cue            # generated docs/index
```

---

# 14. First implementation slice

## Slice 1: read-only code-intel surface

```text
Goal:
  expose workspace, files, symbols, diagnostics, and contracts with no mutation.

Include:
  - Component contract schema
  - Adapter contract schema
  - Resource contract schema
  - Tool contract schema
  - Evidence schema
  - MCP projection manifest

Adapters:
  - workspace/git adapter
  - VFS read adapter
  - CUE validation adapter
  - LuaLS adapter
  - diagnostics aggregator

MCP resources:
  - codeintel://workspace/current
  - codeintel://contracts/components
  - codeintel://diagnostics/current
  - codeintel://graph/symbols

MCP tools:
  - codeintel.workspace.describe
  - codeintel.vfs.read
  - codeintel.contract.validate
  - codeintel.diagnostics.list
  - codeintel.symbol.lookup
```

## Hard constraints

```text
No writes.
No shell escape except declared validation commands.
No unscoped filesystem reads.
No tool without contract.
No adapter without rationale.
No claim without evidence.
```

---

# 15. Working invariant

The core invariant should be:

```text
Agent-visible MCP capability
  must be projected from
Typed CUE contract
  backed by
Adapter rationale + authority + evidence
  executed through
Policy-gated workflow phase
```

That gives you the architecture you want:

```text
CUE contract graph = authority
MCP = projection layer
Adapters = controlled plant interfaces
Workflow = controller trajectory
Evidence = feedback memory
Policy = safety envelope
```
