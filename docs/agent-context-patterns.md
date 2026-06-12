
An **agent context resolver** is the stack that answers:

```text
Given a user request, repo state, tool surface, memory/evidence sources, and token budget,
what exact context should an agent receive before it acts?
```

It converts broad, messy context into a bounded, typed, provenance-backed context packet.

Typical components:

```text
user request / task intent
→ workspace root / repo resolver
→ source inventory
→ contract graph
→ code-intel graph
→ VCS state
→ memory / prior decisions
→ tool capability registry
→ policy / permission model
→ relevance scorer
→ freshness checker
→ context packet projection
→ agent / MCP prompt-tool boundary
```

The resolver is not a search box. It is a control surface for deciding what the agent is allowed to know, what it must know, what is stale, what is missing, and what evidence supports the selected context.

---

# Controlled implementation discovery

Implementation text discovery is exposed only through the `cue.search_implementation` MCP tool. Raw `rg` is a private backend and is not agent-visible.

```text
resolver projection
→ selected graph artifact IDs
→ cue.search_implementation MCP request
→ CUE searchExecutionPlan
→ Go validates the plan
→ Go executes argv-based rg without a shell
→ contract-valid MCP evidence result
```

The CUE plan resolves every requested artifact ID against the immutable projection and emits only relative artifact paths. The Go runtime rejects unsafe or incomplete plans before invoking `rg`. Empty text-search results are observations, not proof of semantic absence.

`cue.search_implementation` is not a `cue cmd` command. It is a Go-registered MCP tool whose request, plan, execution, and result are constrained by CUE contracts.

---

# 1. Task intent extraction

| Field                  | Description                                                                                                                                             |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “What is the user asking the agent to do?”                                                                                                              |
| **Conceptual problem** | User requests are natural-language, partial, and often refer to prior project state. The resolver must normalize the request before collecting context. |
| **Solution**           | Extract task type, target entities, requested output, constraints, and implied workflow phase.                                                          |
| **Typical tools**      | Prompt parser, CUE task schema, intent classifier, issue template, CLI flags.                                                                           |
| **Relates to**         | Context selection, workflow planning, tool authorization, evidence requirements.                                                                        |

**Pattern**

```text
user request
→ intent schema
→ task target + constraints + expected output
```

**Example**

```text
“Generate a similar document for agent-context-resolver and vcs-patch-stack”

→ task.type = docs.generate
→ targets = ["agent-context-resolver", "vcs-patch-stack"]
→ style_anchor = docs/code-intel.md
→ output = markdown drafts
```

Task intent is upstream of all context resolution.

---

# 2. Workspace root resolution

| Field                  | Description                                                                                                     |
| ---------------------- | --------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “Which project/repo/context does this request belong to?”                                                       |
| **Conceptual problem** | Agents can be invoked from the wrong directory, a nested package, a generated file, or a detached working tree. |
| **Solution**           | Resolve root from cwd, file URI, git top-level, `cue.mod`, project registry, or explicit task target.           |
| **Typical tools**      | Git, fd, project registry, MCP roots, CUE module resolver.                                                      |
| **Relates to**         | Source inventory, VCS state, code-intel root detection, policy envelope.                                        |

**Pattern**

```text
cwd / uri / task target
→ root markers
→ normalized workspace root
→ operating envelope
```

**Example**

```text
/home/x404/src/contract.cuemod/docs/code-intel.md
→ repo root = /home/x404/src/contract.cuemod
→ module root = cue.mod
→ docs surface = docs/
```

Root resolution defines the maximum filesystem scope for the resolver.

---

# 3. Source inventory

| Field                  | Description                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “What files, docs, contracts, generated artifacts, and state sources exist?”                                     |
| **Conceptual problem** | The agent needs a map of available sources before selecting relevant context.                                    |
| **Solution**           | Build a typed inventory of files, contracts, docs, indexes, generated artifacts, VCS refs, and evidence ledgers. |
| **Typical tools**      | `fd`, `rg`, git ls-files, CUE package listing, MCP resources, manifest files.                                    |
| **Relates to**         | Context selection, provenance, freshness, contract graph, code-intel graph.                                      |

**Pattern**

```text
workspace root
→ source scanners
→ typed inventory
→ selectable context candidates
```

**Example inventory**

```text
docs/code-intel.md
cue.mod/module.cue
internal/mcp/server.go
internal/cueadapter/adapter.go
patchplan/out/reports/report.json
```

The source inventory is the resolver’s sensor layer.

---

# 4. Contract graph lookup

| Field                  | Description                                                                                                                   |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “What contract defines this component, adapter, interface, or workflow?”                                                      |
| **Conceptual problem** | Implementation files are not enough; agents need intended shape, invariants, non-goals, and policy boundaries.                |
| **Solution**           | Resolve task entities to contract graph nodes and include their rationale, interfaces, invariants, and evidence requirements. |
| **Typical tools**      | CUE, JSON Schema, generated manifest, contract index, MCP contract resources.                                                 |
| **Relates to**         | Code-intel, validation, adapter safety, workflow modeling.                                                                    |

**Pattern**

```text
task target
→ contract graph lookup
→ component/interface/workflow contract
→ context packet
```

**Example**

```text
target = "patchplan MCP adapter"
→ contract node = adapter.patchplan
→ include: rationale, allowed tools, output resources, failure modes
```

Contract graph lookup gives the resolver authority.

---

# 5. Code-intel graph lookup

| Field                  | Description                                                                                                     |
| ---------------------- | --------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “Which symbols, files, modules, and diagnostics are relevant to this task?”                                     |
| **Conceptual problem** | Text search can find names, but it does not understand definitions, references, imports, types, or diagnostics. |
| **Solution**           | Query the code-intel surface for symbols, definitions, references, diagnostics, and dependency edges.           |
| **Typical tools**      | LSP, parser, tree-sitter, CUE LSP, lua_ls, gopls, MCP code-intel resources.                                     |
| **Relates to**         | Source inventory, impact analysis, patch planning, validation.                                                  |

**Pattern**

```text
task entity
→ symbol/definition/reference graph
→ relevant implementation slice
```

**Example**

```text
PatchplanAdapter
→ definition
→ Demo / Validate / ReadReport methods
→ command runner
→ report parser
→ tests
```

Code-intel graph lookup is the semantic selection layer.

---

# 6. VCS state lookup

| Field                  | Description                                                                                                         |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “What has changed, what is staged, and what commit/branch state applies?”                                           |
| **Conceptual problem** | Agent actions are unsafe without knowing dirty files, staged hunks, branch base, and recent commits.                |
| **Solution**           | Read normalized VCS state: status, branch, HEAD, upstream, staged diff, unstaged diff, untracked files, recent log. |
| **Typical tools**      | Git, go-git, gix, Git MCP, custom VCS adapter.                                                                      |
| **Relates to**         | Patch stack, rollback, context freshness, safety gating.                                                            |

**Pattern**

```text
repo root
→ VCS adapter
→ normalized working tree/index/HEAD state
→ context packet
```

**Example**

```text
branch = contract-mcp
dirty = docs/code-intel.md modified
staged = none
HEAD = feat(mcp): add patchplan adapter contracts
```

VCS state is mandatory before any mutation workflow.

---

# 7. Prior decision retrieval

| Field                  | Description                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------------- |
| **Use case**           | “What did we already decide about this architecture?”                                                    |
| **Conceptual problem** | Agents lose project continuity unless prior decisions are represented as context with provenance.        |
| **Solution**           | Retrieve decision records, issue summaries, commit messages, prior workflow outputs, and evidence notes. |
| **Typical tools**      | ADR docs, Git history, issue tracker, conversation summaries, evidence ledger.                           |
| **Relates to**         | Task intent, contract graph, non-goals, workflow constraints.                                            |

**Pattern**

```text
task target
→ prior decision search
→ accepted decisions + rejected alternatives
→ context constraints
```

**Example**

```text
Decision:
  Do not build VFS first.
  Expose patchplan artifacts as MCP resources.
  Keep CUE as authority.
```

Prior decisions prevent architectural drift.

---

# 8. Relevance scoring

| Field                  | Description                                                                                                                 |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “Which context candidates matter most?”                                                                                     |
| **Conceptual problem** | The resolver may find too many files, symbols, docs, and history records for the agent’s budget.                            |
| **Solution**           | Score candidates by direct mention, graph proximity, contract authority, recency, diagnostic relevance, and workflow phase. |
| **Typical tools**      | Graph scoring, lexical search, embeddings, recency filters, hand-authored priority rules.                                   |
| **Relates to**         | Token budgeting, prompt packing, freshness, evidence tracking.                                                              |

**Pattern**

```text
candidate context set
→ score by task relevance + authority + freshness
→ ranked context slice
```

**Scoring dimensions**

| Dimension  | Question                                    |
| ---------- | ------------------------------------------- |
| Directness | Was this entity named by the user?          |
| Authority  | Is this contract/source authoritative?      |
| Proximity  | Is this near the target in the graph?       |
| Freshness  | Could this be stale?                        |
| Risk       | Does omission make action unsafe?           |
| Cost       | How many tokens/tool calls does it consume? |

Relevance scoring is the resolver’s selection policy.

---

# 9. Freshness checking

| Field                  | Description                                                                                                     |
| ---------------------- | --------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “Can this context still be trusted?”                                                                            |
| **Conceptual problem** | Cached context becomes wrong when files, contracts, generated artifacts, dependencies, or branches change.      |
| **Solution**           | Attach hashes, mtimes, git object IDs, tool versions, config hashes, and invalidation rules to context records. |
| **Typical tools**      | Git blob hashes, file hashes, index cache keys, LSP document versions, CUE export hashes.                       |
| **Relates to**         | Evidence tracking, cache management, generated artifacts, validation.                                           |

**Pattern**

```text
context record
→ freshness key
→ compare against current source state
→ accept / invalidate / recompute
```

**Cache contract**

```text
input hash + tool version + config hash + root identity = valid context
```

Freshness is a safety requirement, not an optimization.

---

# 10. Conflict resolution

| Field                  | Description                                                                         |
| ---------------------- | ----------------------------------------------------------------------------------- |
| **Use case**           | “What if sources disagree?”                                                         |
| **Conceptual problem** | Conversation memory, docs, code, generated artifacts, and diagnostics may conflict. |
| **Solution**           | Rank sources by authority and recency; surface unresolved conflicts explicitly.     |
| **Typical tools**      | Contract graph, VCS timestamps, evidence ledger, source priority rules.             |
| **Relates to**         | Prior decisions, evidence, validation, policy.                                      |

**Pattern**

```text
conflicting claims
→ authority ordering
→ newest valid evidence
→ resolved claim or explicit conflict
```

**Authority order example**

```text
CUE contract
> committed source
> generated artifact with valid source map
> current diagnostics
> issue draft
> conversation note
```

Conflict resolution prevents false certainty.

---

# 11. Context packet construction

| Field                  | Description                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------ |
| **Use case**           | “What exact bundle should the agent receive?”                                                                |
| **Conceptual problem** | Agents need structured, compact packets instead of raw piles of files and logs.                              |
| **Solution**           | Build a typed packet with task, constraints, selected sources, omitted sources, evidence, and allowed tools. |
| **Typical tools**      | CUE schema, JSON projection, MCP resources, prompt templates.                                                |
| **Relates to**         | Prompt packing, token budget, policy gates, workflow execution.                                              |

**Pattern**

```text
task + ranked context + policy
→ context packet
→ agent prompt/tool call boundary
```

**Packet shape**

```json
{
  "task": {
    "type": "docs.generate",
    "targets": ["agent-context-resolver", "vcs-patch-stack"]
  },
  "constraints": [
    "contract first",
    "every component requires rationale",
    "every interface requires contract"
  ],
  "sources": [
    {
      "uri": "repo://docs/code-intel.md",
      "role": "style-anchor",
      "freshness": "current"
    }
  ],
  "allowed_tools": [
    "codeintel.read",
    "vcs.status",
    "contract.validate"
  ],
  "evidence": []
}
```

The context packet is the resolver’s main output.

---

# 12. Token budget control

| Field                  | Description                                                                                                                         |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “How much context can fit?”                                                                                                         |
| **Conceptual problem** | Agents have finite context windows, and irrelevant context degrades reasoning.                                                      |
| **Solution**           | Allocate context budget across task intent, authority contracts, implementation slices, diagnostics, evidence, and prior decisions. |
| **Typical tools**      | Token counters, summarizers, graph slicing, progressive disclosure, MCP resource references.                                        |
| **Relates to**         | Relevance scoring, prompt packing, evidence links.                                                                                  |

**Pattern**

```text
ranked context
→ budget allocation
→ include full / summarize / reference / omit
```

**Budget classes**

| Class                 | Treatment                     |
| --------------------- | ----------------------------- |
| Critical contract     | include full or exact excerpt |
| Target implementation | include relevant slice        |
| Supporting docs       | summarize                     |
| Large logs            | reference with URI            |
| Low relevance         | omit                          |

Token budget control is a constraint solver.

---

# 13. Progressive context expansion

| Field                  | Description                                                                                                              |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| **Use case**           | “What should the agent fetch next?”                                                                                      |
| **Conceptual problem** | Initial context may be insufficient; blindly loading everything is wasteful.                                             |
| **Solution**           | Use staged expansion: start with contract and graph, then fetch target files, diagnostics, tests, and history as needed. |
| **Typical tools**      | MCP resources, graph queries, file search, LSP lookup, VCS diff readers.                                                 |
| **Relates to**         | Token budget, workflow phases, evidence tracking.                                                                        |

**Pattern**

```text
minimal packet
→ agent identifies gap
→ resolver expands specific context
→ updated packet
```

**Expansion ladder**

```text
contract summary
→ target symbol/file
→ references/dependencies
→ diagnostics/tests
→ history/evidence
```

Progressive expansion keeps the agent bounded and responsive.

---

# 14. Policy and permission filtering

| Field                  | Description                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Use case**           | “What context is the agent allowed to see or use?”                                         |
| **Conceptual problem** | Some context may be private, irrelevant, unsafe, stale, or outside the declared workspace. |
| **Solution**           | Filter by workspace scope, trust zone, sensitivity, tool permission, and workflow phase.   |
| **Typical tools**      | MCP roots, authz policy, CUE policy schema, allowlists, deny rules.                        |
| **Relates to**         | Context packet, tool authorization, evidence.                                              |

**Pattern**

```text
candidate context
→ policy gate
→ allowed / denied / redacted / requires approval
```

**Example**

```text
Allowed:
  repo docs
  generated artifacts
  current VCS state

Denied:
  files outside repo root
  credentials
  unrelated personal data
  unscoped shell output
```

Policy filtering makes context resolution safe.

---

# 15. Evidence binding

| Field                  | Description                                                                                               |
| ---------------------- | --------------------------------------------------------------------------------------------------------- |
| **Use case**           | “Why does the agent believe this context?”                                                                |
| **Conceptual problem** | A context packet without provenance is just prompt stuffing.                                              |
| **Solution**           | Attach evidence records linking selected context to files, hashes, commands, diagnostics, and timestamps. |
| **Typical tools**      | Evidence ledger, git hashes, test output, CUE validation reports, MCP resource metadata.                  |
| **Relates to**         | Freshness, conflict resolution, validation, audit.                                                        |

**Pattern**

```text
claim
→ source
→ artifact/hash
→ validator
→ result
→ evidence record
```

**Example**

```json
{
  "claim": "docs/code-intel.md is the style anchor",
  "source": "docs/code-intel.md",
  "validator": "git blob hash",
  "result": "current"
}
```

Evidence binding turns context into an auditable input.

---

# 16. Prompt projection

| Field                  | Description                                                                    |
| ---------------------- | ------------------------------------------------------------------------------ |
| **Use case**           | “How does resolved context become agent-operable input?”                       |
| **Conceptual problem** | Context records are structured; agents consume prompt/tool surfaces.           |
| **Solution**           | Project the context packet into a prompt, MCP resource set, or tool-call plan. |
| **Typical tools**      | MCP prompts, MCP resources, JSON prompt packets, CUE projection.               |
| **Relates to**         | Workflow modeling, agent adapter, token budget.                                |

**Pattern**

```text
context packet
→ projection template
→ agent prompt + resource links + allowed tools
```

**Example**

```text
System context:
  You are editing contract docs.

Task context:
  Generate docs/agent-context-resolver.md.

Authority:
  docs/code-intel.md structure.

Allowed tools:
  read-only repo inspection.
```

Prompt projection is an adapter, not the authority.

---

# 17. Tool-surface selection

| Field                  | Description                                                            |
| ---------------------- | ---------------------------------------------------------------------- |
| **Use case**           | “Which tools may the agent call for this task?”                        |
| **Conceptual problem** | Giving the agent every tool increases risk and noise.                  |
| **Solution**           | Select tools based on task phase, policy, root, and required evidence. |
| **Typical tools**      | MCP tool registry, CUE capability graph, risk classifier.              |
| **Relates to**         | Policy, workflow execution, context packet.                            |

**Pattern**

```text
task + phase + policy
→ allowed tool subset
→ agent tool surface
```

**Example**

```text
docs.generate phase:
  allow: repo.read, docs.search, contract.inspect
  deny: patch.apply, git.commit, shell.exec
```

Tool selection is part of context resolution because tools shape what the agent can learn next.

---

# 18. Missing-context elicitation

| Field                  | Description                                                                  |
| ---------------------- | ---------------------------------------------------------------------------- |
| **Use case**           | “What does the resolver still need?”                                         |
| **Conceptual problem** | Some constraints cannot be inferred safely from repo state.                  |
| **Solution**           | Emit a missing-context report or ask a targeted question only when required. |
| **Typical tools**      | MCP elicitation, task schema validation, issue templates.                    |
| **Relates to**         | Task intent, workflow blocking, policy.                                      |

**Pattern**

```text
required context schema
→ missing fields
→ infer / default / elicit / block
```

**Example**

```text
Missing:
  target branch for commit
  write permission for generated file
  desired public API name
```

Elicitation should be specific and schema-backed.

---

# 19. Context replay

| Field                  | Description                                                                                                     |
| ---------------------- | --------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “Can we reproduce what the agent knew when it acted?”                                                           |
| **Conceptual problem** | Debugging agent decisions requires knowing the exact context packet, not just final output.                     |
| **Solution**           | Persist context packet metadata, source hashes, selected resources, omitted resources, and tool capability set. |
| **Typical tools**      | Evidence ledger, workflow trace, JSON packet archive, git notes.                                                |
| **Relates to**         | Audit, rollback, validation, workflow reproducibility.                                                          |

**Pattern**

```text
context packet
→ immutable replay record
→ later audit / rerun / diff
```

**Example**

```text
agent-run-2026-06-11:
  task = docs.generate
  selected sources = docs/code-intel.md
  omitted sources = generated artifacts
  tool surface = read-only
```

Context replay makes agent behavior debuggable.

---

# 20. MCP context resource adapter

| Field                  | Description                                                                            |
| ---------------------- | -------------------------------------------------------------------------------------- |
| **Use case**           | “Expose resolved context to agents over MCP.”                                          |
| **Conceptual problem** | Agents need structured, discoverable context instead of arbitrary filesystem reads.    |
| **Solution**           | Expose context packets, selected sources, evidence, and graph slices as MCP resources. |
| **Typical tools**      | MCP resources, Go adapter, CUE projection, JSON resource registry.                     |
| **Relates to**         | Prompt projection, tool selection, policy gates.                                       |

**Pattern**

```text
resolver output
→ context://packet/{id}
→ context://sources/{id}
→ context://evidence/{id}
→ MCP resource read
```

**Example resources**

```text
context://task/current
context://packet/latest
context://sources/selected
context://evidence/latest
context://policy/allowed-tools
```

MCP resources are the read-only projection of the resolver.

The `agent-context-resolver` slice in this repo now models that boundary as a lifecycle:

```text
turn-start native fragments -> prompt classification -> selected known IDs -> scoped report
```

That keeps context authority in the contract layer and keeps runtime/tool output out of the implied model context path.

---

# Relationship map

```text
user request
  ↓
task intent
  ↓
workspace root ───────→ policy envelope
  ↓                         ↓
source inventory        allowed tools
  ↓                         ↓
contract graph ─────→ context candidates
  ↓                         ↓
code-intel graph ───→ relevance scoring
  ↓                         ↓
VCS state ──────────→ freshness checking
  ↓                         ↓
prior decisions ────→ conflict resolution
  ↓                         ↓
evidence binding ───→ context packet
  ↓
prompt / MCP projection
  ↓
agent action
```

---

# Layered maturity model

## Level 0 — Manual prompt stuffing

```text
copy files into prompt
```

| Strength | Weakness                               |
| -------- | -------------------------------------- |
| Simple   | No provenance, no freshness, no policy |

Use only for tiny tasks.

---

## Level 1 — Search-based context

```text
rg, fd, grep, file search
```

| Strength       | Weakness                                  |
| -------------- | ----------------------------------------- |
| Fast and broad | Lexical, noisy, misses semantic relations |

Use for initial discovery.

---

## Level 2 — Project-aware context

```text
root detection, git state, source inventory
```

| Strength                 | Weakness                   |
| ------------------------ | -------------------------- |
| Knows project boundaries | Still mostly file-oriented |

Use before any repo mutation.

---

## Level 3 — Graph-aware context

```text
contracts, symbols, references, dependency graph
```

| Strength                             | Weakness                                 |
| ------------------------------------ | ---------------------------------------- |
| Selects relevant slices semantically | Requires code-intel and contract indexes |

Use for refactor, codegen, and architecture work.

---

## Level 4 — Evidence-backed context

```text
context packet + provenance + freshness
```

| Strength                   | Weakness                               |
| -------------------------- | -------------------------------------- |
| Auditable and reproducible | Requires ledger and invalidation rules |

Use for agent workflow validation.

---

## Level 5 — Agent-operable resolver

```text
MCP context resources + tool selection + policy gates
```

| Strength                              | Weakness                             |
| ------------------------------------- | ------------------------------------ |
| Agents receive bounded, typed context | Requires strict schemas and adapters |

Use for automated agent control planes.

---

# Practical pattern stack for contract.cuemod

Given the project direction, the strong stack is:

```text
CUE task/context contract
→ workspace + VCS resolver
→ source inventory
→ contract graph lookup
→ code-intel graph lookup
→ relevance/freshness scoring
→ context packet JSON
→ MCP context resources
→ agent prompt/tool projection
→ evidence ledger
```

## Minimal viable toolchain

| Layer              | Tool                               |
| ------------------ | ---------------------------------- |
| Lexical discovery  | `rg`, `fd`                         |
| Workspace state    | Git, project registry              |
| Contract authority | CUE                                |
| Code-intel facts   | LSP / parser / patchplan artifacts |
| Context projection | JSON / MCP resources               |
| Policy             | CUE rules                          |
| Evidence           | hashes, reports, workflow trace    |

---

# Best pattern names to keep

| Pattern                      | Core question                      |
| ---------------------------- | ---------------------------------- |
| Task intent extraction       | What is being asked?               |
| Workspace root resolution    | Which project applies?             |
| Source inventory             | What context sources exist?        |
| Contract graph lookup        | What is the intended shape?        |
| Code-intel graph lookup      | What implementation slice matters? |
| VCS state lookup             | What repo state constrains action? |
| Prior decision retrieval     | What was already decided?          |
| Relevance scoring            | What should be included?           |
| Freshness checking           | Can this context be trusted?       |
| Conflict resolution          | Which source wins?                 |
| Context packet construction  | What does the agent receive?       |
| Token budget control         | What fits?                         |
| Progressive expansion        | What should be fetched next?       |
| Policy filtering             | What is allowed?                   |
| Evidence binding             | Why do we trust it?                |
| Prompt projection            | How is context presented?          |
| Tool-surface selection       | What may the agent call?           |
| Missing-context elicitation  | What is still needed?              |
| Context replay               | Can the run be reproduced?         |
| MCP context resource adapter | How is context exposed safely?     |
