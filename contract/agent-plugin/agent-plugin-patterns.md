
# Agent Plugin Patterns

## Problem

Agent-facing capabilities are currently projected as separate workflow surfaces:

* context resolution
* VCS patch stack mutation
* code intelligence
* evidence capture
* validation

These surfaces are not independent plugins. They share runtime concepts:

* graph IDs
* projection IDs
* evidence IDs
* provider IDs
* validation IDs
* MCP result semantics
* legality and policy constraints
* workflow command groups

Treating each surface as a separate plugin package would create artificial boundaries. It would duplicate runtime wiring, fragment evidence identity, and make cross-surface validation harder to reason about.

The system needs one packaged agent-facing plugin surface that binds these workflows together while preserving strict authority boundaries.

## Pattern

Use a single packaged agent plugin bundle.

```text
Agent Plugin Bundle
  = Open Plugin bundle
  + generated workflow skills
  + MCP runtime server
  + CUE authority contracts
  + evidence/validation model
```

The plugin bundle packages multiple workflow skills and one MCP server.

Each skill is a thin model-facing workflow adapter. The MCP server exposes controlled public workflow command groups. CUE contracts define what is legal, what must be validated, what evidence must exist, and which backend capabilities may be used.

Open Plugin is the portable shipping and discovery envelope. It is not the authority model.

## Control Loop

```text
User prompt
  → resolve-agent-context skill
  → context.resolve
  → projection_id
  → selected workflow surface
  → MCP command group
  → CUE validation
  → private backend adapter
  → evidence/result
  → final answer with evidence
```

The model should not select raw backend tools directly.

The model consumes workflow skills. Workflow skills constrain the model toward public MCP command groups. MCP maps those public groups to private backend capabilities. CUE validates legality, policy, evidence, and result shape.

## Layering

| Layer | Owner                   | Responsibility                                                |
| ----: | ----------------------- | ------------------------------------------------------------- |
|     0 | CUE contracts           | Authority, legality, policy, evidence, validation, invariants |
|     1 | Contract MCP runtime    | Controlled execution interface and result transport           |
|     2 | Open Plugin package     | Portable packaging and discovery envelope                     |
|     3 | Codex/OpenAI projection | Host-specific plugin and agent metadata projection            |
|     4 | Workflow skills         | Model-facing procedural adapters                              |

The dependency direction is downward:

```text
SKILL.md
  depends on projected host metadata and MCP commands

MCP runtime
  depends on CUE legality and backend adapters

Open Plugin
  packages the plugin bundle
  but does not define legality

CUE
  remains the authority root
```

## Bundle Anatomy

```text
contract-agent-runtime/
  .plugin/
    plugin.json

  .codex-plugin/
    plugin.json

  .mcp.json

  skills/
    resolve-agent-context/
      SKILL.md
      agents/openai.yaml

    vcs/
      SKILL.md
      agents/openai.yaml

    code-intel/
      SKILL.md
      agents/openai.yaml

  references/
    resolve-agent-context.md
    vcs.md
    code-intel.md

  assets/
    schemas/
    examples/
```

The directory may still be named `contract-agent-runtime` because it packages a runtime-capable agent plugin. The conceptual pattern is **Agent Plugin Bundle**.

## Skill Cardinality

Use one skill per workflow boundary:

* `resolve-agent-context`
* `vcs`
* `code-intel`

Do not use one mega-skill for the whole plugin bundle.

The bundle is unified at the package/runtime layer, not at the skill layer.

## MCP Cardinality

Use one MCP server for the plugin bundle.

The MCP server exposes public workflow command groups and hides backend namespaces.

```text
Contract MCP server
  exposes public workflow tools
  maps to private backend capabilities
  returns typed evidence/result payloads
  remains constrained by CUE authority
```

One MCP runtime gives the plugin bundle a shared execution plane for:

* context routing
* projection resolution
* VCS patch stack workflows
* code intelligence workflows
* evidence capture
* validation
* result normalization

## Public Workflow Command Groups

Public command groups are agent-visible workflow interfaces.

Examples:

```text
context.*
projection.*
stack.*
evidence.*
validation.*
codeIntel.*
symbol.*
diagnostics.*
```

These names describe workflow intent, not backend implementation.

## Private Backend Namespaces

Backend namespaces remain private implementation capabilities.

Examples:

```text
vcs.*
cue.*
cue_lsp.*
lua_lsp.*
gopls.*
rg.*
ast_grep.*
filesystem.*
```

These namespaces may be used by the MCP server, adapters, or generated internal plans, but they are not directly agent-visible.

The agent should not be instructed to call raw backend capabilities such as `gopls.*`, `rg.*`, `ast_grep.*`, or `filesystem.*`.

## Authority Boundaries

| Surface               | Authority                                          |
| --------------------- | -------------------------------------------------- |
| Open Plugin manifest  | Package discovery and portable bundle metadata     |
| Codex plugin manifest | Codex-specific generated projection                |
| `SKILL.md`            | Model-facing workflow instructions                 |
| `agents/openai.yaml`  | Host metadata, dependencies, and interface hints   |
| MCP server            | Runtime execution and result transport             |
| CUE contracts         | Legality, policy, evidence, validation, invariants |

Critical invariant:

```text
Packaging does not define legality.
Projection does not define authority.
Runtime execution must be contract-constrained.
```

## Runtime Invariants

The initial bundle contract should encode these invariants:

1. One plugin bundle packages all workflow surfaces.
2. One MCP server exposes controlled public workflow command groups.
3. Skills are thin workflow adapters, not backend implementations.
4. Open Plugin manifest is packaging and discovery only.
5. CUE contracts remain authority for legality, policy, evidence, and validation.
6. Raw backend namespaces are not agent-visible.
7. Codex-specific plugin manifest is a generated projection.
8. `agents/openai.yaml` is host metadata/dependency/interface projection, not authority.
9. Workflow skills must map to public MCP command groups.
10. Public MCP command groups may map to private backend capabilities.

## Non-goals

This pattern seed does not implement:

* full plugin installer behavior
* marketplace support
* full MCP server implementation
* full code-intel workflow
* full VCS patch-stack workflow
* binary distribution
* provenance verification
* Open Plugin conformance test suite
* migration of existing VCS/code-intel contracts
* hand-edited generated Codex skill projections

## Design Constraint

The plugin bundle must preserve the existing authority split:

```text
Open Plugin
  = packaging/discovery

Codex plugin
  = host projection

SKILL.md
  = workflow adapter

agents/openai.yaml
  = OpenAI/Codex metadata adapter

MCP
  = controlled runtime interface

CUE
  = authority, policy, validation, evidence
```

## Summary

Use one **Agent Plugin Bundle**, one MCP server, and multiple thin workflow skills.

The plugin bundle gives the agent a coherent packaged surface. The skills give the model constrained workflow entry points. MCP executes controlled public commands. Private backend capabilities remain hidden. CUE remains the authority for legality, policy, validation, evidence, and invariants.
