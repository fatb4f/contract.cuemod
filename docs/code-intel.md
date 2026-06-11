
## Code intelligence toolchain use case patterns

A **code intelligence toolchain** is the stack that answers questions about code structure, symbols, types, references, diagnostics, edits, and project state.

Typical components:

```text
filesystem / VFS
→ parser / tree-sitter
→ indexer
→ type checker / compiler
→ language server / LSP
→ editor / agent / MCP adapter
→ actions: navigation, diagnostics, refactor, codegen, validation
```

---

# 1. Symbol discovery

| Field                  | Description                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **Use case**           | “What symbols exist in this project?”                                                                                          |
| **Conceptual problem** | Source code is text, but users and agents think in named entities: functions, classes, modules, fields, commands, config keys. |
| **Solution**           | Parse files, extract declarations, build a symbol table or workspace index.                                                    |
| **Typical tools**      | LSP `workspace/symbol`, tree-sitter queries, compiler metadata, ctags, gopls, lua_ls, rust-analyzer.                           |
| **Relates to**         | Navigation, reference search, refactor, docs generation, dependency graphing.                                                  |

**Pattern**

```text
files → parse → declarations → symbol index
```

**Example**

```text
Find all exported Lua modules in dotfiles.
Find all CUE definitions under contract.cuemod.
Find all WezTerm config entrypoints.
```

---

# 2. Go-to-definition / declaration resolution

| Field                  | Description                                                                                                                             |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “Where is this thing defined?”                                                                                                          |
| **Conceptual problem** | A symbol use is not enough; you need to resolve it through imports, scopes, aliases, module paths, generated files, and language rules. |
| **Solution**           | Use compiler or LSP resolver to map symbol usage to canonical definition.                                                               |
| **Typical tools**      | LSP `textDocument/definition`, `declaration`, compiler frontend, import resolver.                                                       |
| **Relates to**         | Type inference, dependency graph, rename safety, provenance tracking.                                                                   |

**Pattern**

```text
symbol use → scope/import resolution → definition location
```

**Example**

```text
wezterm.action.SplitHorizontal
→ resolve to WezTerm Lua type definition
```

This pattern depends on **symbol discovery**, but adds semantic rules.

---

# 3. Reference search

| Field                  | Description                                                       |
| ---------------------- | ----------------------------------------------------------------- |
| **Use case**           | “Where is this thing used?”                                       |
| **Conceptual problem** | Text search creates false positives and misses semantic aliases.  |
| **Solution**           | Use LSP/compiler index to find semantic references.               |
| **Typical tools**      | LSP `textDocument/references`, `workspace/symbol`, `rg` fallback. |
| **Relates to**         | Rename, dead-code detection, impact analysis, dependency graph.   |

**Pattern**

```text
definition → semantic index → usage locations
```

**Important distinction**

```text
rg "foo"         = lexical search
LSP references  = semantic search
```

Reference search is the inverse of **go-to-definition**.

---

# 4. Type inspection

| Field                  | Description                                                                                                                                                |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “What type is this expression?”                                                                                                                            |
| **Conceptual problem** | The visible code often omits types. Actual type depends on inference, imports, generics, overloads, annotations, schema constraints, or runtime libraries. |
| **Solution**           | Ask type checker / LSP for inferred type at position.                                                                                                      |
| **Typical tools**      | LSP `hover`, `signatureHelp`, `typeDefinition`, compiler APIs.                                                                                             |
| **Relates to**         | Completion, diagnostics, codegen, adapter contracts.                                                                                                       |

**Pattern**

```text
expression position → type checker → inferred type
```

**Example**

```lua
---@type wezterm.Config
local config = {}

config.keys = {
  {
    key = "Enter",
    mods = "CTRL",
    action = wezterm.action.SendKey { key = "j", mods = "CTRL" },
  },
}
```

Here `lua_ls` can validate the shape only if the WezTerm types are available.

---

# 5. Completion

| Field                  | Description                                                                                    |
| ---------------------- | ---------------------------------------------------------------------------------------------- |
| **Use case**           | “What can I write here?”                                                                       |
| **Conceptual problem** | Valid next tokens depend on type, scope, imports, language grammar, and partial text.          |
| **Solution**           | Use LSP completion backed by parser, type checker, imports, snippets, docs, and project index. |
| **Typical tools**      | LSP `completion`, snippets, AI completion, compiler services.                                  |
| **Relates to**         | Type inspection, documentation, codegen, diagnostics.                                          |

**Pattern**

```text
cursor context → scope + type + grammar → candidate completions
```

**Levels**

| Level           | Completion kind                           |
| --------------- | ----------------------------------------- |
| Lexical         | words already in buffer                   |
| Symbolic        | functions, variables, modules             |
| Typed           | fields/methods valid for current type     |
| Contract-driven | values valid under schema or domain model |
| Generative      | AI proposes larger code blocks            |

Typed completion is downstream of **symbol discovery** and **type inspection**.

---

# 6. Diagnostics

| Field                  | Description                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **Use case**           | “What is wrong?”                                                                                                               |
| **Conceptual problem** | Errors exist across multiple layers: syntax, type, imports, schema, lint rules, formatting, build config, runtime assumptions. |
| **Solution**           | Aggregate diagnostics from parser, compiler, linter, formatter, test runner, and custom validators.                            |
| **Typical tools**      | LSP `publishDiagnostics`, compiler, eslint, biome, luacheck, cue vet, gopls, lua_ls.                                           |
| **Relates to**         | Quick fixes, validation, CI, agent repair loops.                                                                               |

**Pattern**

```text
source → analyzers → diagnostic stream → editor/agent feedback
```

**Diagnostic layers**

| Layer       | Example                         |
| ----------- | ------------------------------- |
| Syntax      | missing `end` in Lua            |
| Type        | wrong field type                |
| Import      | unresolved module               |
| Schema      | config violates CUE contract    |
| Lint        | unused local                    |
| Runtime     | config loads but behavior fails |
| Integration | adapter boundary mismatch       |

Diagnostics are the main feedback loop for **repair**, **refactor**, and **codegen**.

---

# 7. Quick fix / code action

| Field                  | Description                                                      |
| ---------------------- | ---------------------------------------------------------------- |
| **Use case**           | “Fix this diagnostic.”                                           |
| **Conceptual problem** | A diagnostic should often produce a safe, minimal edit.          |
| **Solution**           | LSP exposes structured code actions, usually as workspace edits. |
| **Typical tools**      | LSP `codeAction`, `workspace/applyEdit`, compiler quick fixes.   |
| **Relates to**         | Diagnostics, refactor, import management, formatting.            |

**Pattern**

```text
diagnostic → available actions → workspace edit → revalidate
```

**Example**

```text
unresolved symbol
→ add missing import
→ apply edit
→ rerun diagnostics
```

Code actions operationalize diagnostics.

---

# 8. Rename refactor

| Field                  | Description                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------------- |
| **Use case**           | “Rename this symbol everywhere safely.”                                                      |
| **Conceptual problem** | Text replacement is unsafe because names can collide, shadow, or appear in comments/strings. |
| **Solution**           | Use semantic reference graph to rewrite only real symbol references.                         |
| **Typical tools**      | LSP `rename`, compiler refactor APIs.                                                        |
| **Relates to**         | References, scope resolution, diagnostics, workspace edit.                                   |

**Pattern**

```text
definition → references → conflict check → workspace edit
```

**Requires**

```text
symbol discovery
+ definition resolution
+ reference search
+ scope model
```

Rename is one of the strongest tests of code intelligence maturity.

---

# 9. Structural edit / refactor

| Field                  | Description                                                                         |
| ---------------------- | ----------------------------------------------------------------------------------- |
| **Use case**           | “Extract function”, “move module”, “convert shape”, “split config.”                 |
| **Conceptual problem** | Edits need to preserve syntax, imports, types, formatting, and behavior.            |
| **Solution**           | Use AST-aware transforms, LSP code actions, compiler refactors, or custom codemods. |
| **Typical tools**      | LSP refactors, tree-sitter, ts-morph, go/ast, ast-grep, codemods.                   |
| **Relates to**         | Rename, formatting, diagnostics, codegen.                                           |

**Pattern**

```text
selected region / symbol
→ AST transform
→ workspace edit
→ format
→ diagnostics/test validation
```

**Example**

```text
inline WezTerm key table
→ extract into typed module
→ preserve wezterm.Config type boundary
```

Structural refactor generalizes **rename** from symbol rewrite to tree rewrite.

---

# 10. Formatting

| Field                  | Description                                                         |
| ---------------------- | ------------------------------------------------------------------- |
| **Use case**           | “Normalize this file’s layout.”                                     |
| **Conceptual problem** | Formatting is syntactic normalization, not semantic transformation. |
| **Solution**           | Formatter parses source and emits canonical layout.                 |
| **Typical tools**      | stylua, gofmt, prettier, biome, cue fmt, black.                     |
| **Relates to**         | Refactor, codegen, save hooks, CI.                                  |

**Pattern**

```text
source text → parser/formatter → normalized text
```

Formatting should usually run after codegen or refactor.

---

# 11. Import/module resolution

| Field                  | Description                                                                                                                                        |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “Can this module be found?”                                                                                                                        |
| **Conceptual problem** | Import paths depend on language rules, workspace roots, package managers, runtime paths, vendoring, symlinks, generated files, and project layout. |
| **Solution**           | Maintain resolver state from project config and language-specific module rules.                                                                    |
| **Typical tools**      | gopls, tsserver/vtsls, lua_ls workspace libraries, CUE module resolver.                                                                            |
| **Relates to**         | Definition resolution, diagnostics, completion, dependency graph.                                                                                  |

**Pattern**

```text
import string → workspace/module resolver → file/package/symbol
```

**Example**

```lua
local smart_splits = require("dotfiles.wezterm.smart_splits")
```

Resolution requires knowing:

```text
runtime.path
workspace.library
package.path
project root
```

This is a major place where editor behavior and runtime behavior diverge.

---

# 12. Workspace root detection

| Field                  | Description                                                                                                            |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “What project am I in?”                                                                                                |
| **Conceptual problem** | Tools need a root to resolve files, configs, packages, diagnostics, and indexes. Wrong root means broken intelligence. |
| **Solution**           | Detect root from markers like `.git`, `go.mod`, `package.json`, `cue.mod`, `.luarc.json`, etc.                         |
| **Typical tools**      | LSP client root detection, direnv, project registry, custom resolver.                                                  |
| **Relates to**         | Import resolution, VFS, indexing, project sessionization.                                                              |

**Pattern**

```text
current file/cwd → root markers → workspace root → tool config
```

**Example**

```text
/home/x404/dotfiles/chezmoi/private_dot_config/wezterm/wezterm.lua
→ root = /home/x404/dotfiles
→ enable lua_ls + wezterm-types + dotfiles library
```

Workspace root detection is upstream of almost everything.

---

# 13. Virtual filesystem / overlay model

| Field                  | Description                                                                                                                                    |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “Analyze files that are generated, templated, projected, unsaved, remote, or virtual.”                                                         |
| **Conceptual problem** | Code intelligence usually expects real files, but modern workflows use generated views, templates, buffers, projections, and remote resources. |
| **Solution**           | Introduce a VFS or overlay that maps logical paths to physical or generated content.                                                           |
| **Typical tools**      | LSP virtual documents, editor buffers, generated files, MCP resource adapters, custom VFS.                                                     |
| **Relates to**         | Indexing, generated code, CUE projections, chezmoi templates, agent tooling.                                                                   |

**Pattern**

```text
logical URI → resolver → content provider → analyzer
```

**Example**

```text
contract://wezterm/config
→ projected from CUE model
→ rendered as Lua
→ checked by lua_ls
```

VFS is an **addressability layer**. It does not replace the resolver; it feeds the resolver stable content and URIs.

---

# 14. Generated code intelligence

| Field                  | Description                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------ |
| **Use case**           | “Can generated files participate in navigation, diagnostics, and completion?”                                |
| **Conceptual problem** | Generated artifacts may not exist yet, may be stale, or may lack source mapping back to the authority model. |
| **Solution**           | Generate artifacts deterministically, index them, and preserve provenance/source maps.                       |
| **Typical tools**      | CUE export, protobuf, OpenAPI generators, TypeScript declaration emit, Lua annotation generation.            |
| **Relates to**         | VFS, schema contracts, codegen, diagnostics, provenance.                                                     |

**Pattern**

```text
authority model → generator → artifact → index/typecheck → source map
```

**Example**

```text
CUE contract
→ generate Lua annotations
→ lua_ls sees typed config surface
→ diagnostics point back to CUE authority
```

This is where **CUE + LuaLS + MCP** becomes high-signal.

---

# 15. Schema-backed validation

| Field                  | Description                                                                          |
| ---------------------- | ------------------------------------------------------------------------------------ |
| **Use case**           | “Does this config satisfy the contract?”                                             |
| **Conceptual problem** | Type systems often validate implementation syntax, but not domain policy.            |
| **Solution**           | Use schemas/contracts to validate allowed shapes, values, relations, and invariants. |
| **Typical tools**      | CUE, JSON Schema, Zod, OpenAPI, protobuf, custom validators.                         |
| **Relates to**         | Diagnostics, codegen, adapters, policy enforcement.                                  |

**Pattern**

```text
artifact/config → normalize → validate against contract → diagnostics
```

**Example**

```text
WezTerm Lua config loads
but violates dotfiles contract:
- missing project launcher binding
- duplicate keymap
- unmanaged external plugin
```

Schema validation complements language typing.

```text
LuaLS validates Lua shape.
CUE validates system contract.
Runtime validates behavior.
```

---

# 16. Dependency graph extraction

| Field                  | Description                                                                                                     |
| ---------------------- | --------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “What depends on what?”                                                                                         |
| **Conceptual problem** | Dependencies are spread across imports, requires, config references, generated artifacts, and runtime adapters. |
| **Solution**           | Extract edges from import graphs, symbol references, schemas, build files, and runtime manifests.               |
| **Typical tools**      | compiler graph, LSP references, tree-sitter, module resolver, package manager metadata.                         |
| **Relates to**         | Impact analysis, refactor, build planning, codegen, architecture docs.                                          |

**Pattern**

```text
nodes: files/symbols/modules/contracts
edges: imports/references/generates/validates/uses
```

**Example graph**

```text
contract.cue
→ generates wezterm-types.lua
→ used by wezterm.lua
→ configures WezTerm runtime
→ launches Neovim project session
```

Dependency graphs give higher-level structure above individual LSP queries.

---

# 17. Impact analysis

| Field                  | Description                                                                                             |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Use case**           | “What breaks if I change this?”                                                                         |
| **Conceptual problem** | Changes propagate through symbols, imports, generated artifacts, tests, configs, and runtime workflows. |
| **Solution**           | Combine reference graph, dependency graph, diagnostics, tests, and contract validation.                 |
| **Typical tools**      | LSP references, build graph, test runner, CI, custom graph queries.                                     |
| **Relates to**         | Refactor, migration, risk scoring, planning.                                                            |

**Pattern**

```text
proposed change → affected graph slice → validators → risk report
```

**Example**

```text
Change project model path normalization
→ affects sessionizer
→ controller.launch
→ WezTerm launch bindings
→ tests/manual-cd behavior
```

Impact analysis is dependency graph + validation loop.

---

# 18. Documentation-on-hover

| Field                  | Description                                                                  |
| ---------------------- | ---------------------------------------------------------------------------- |
| **Use case**           | “What does this symbol mean?”                                                |
| **Conceptual problem** | The user needs local semantic context without leaving the editor.            |
| **Solution**           | LSP hover joins symbol info, type info, comments, docs, examples, and links. |
| **Typical tools**      | LSP `hover`, doc comments, generated docs.                                   |
| **Relates to**         | Completion, type inspection, onboarding, agent explanations.                 |

**Pattern**

```text
symbol at cursor → definition/type/docs → hover payload
```

For typed adapters, hover becomes a contract surface:

```text
field → type → allowed values → policy note → source authority
```

---

# 19. Signature help

| Field                  | Description                                                                                                |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Use case**           | “What arguments does this function take?”                                                                  |
| **Conceptual problem** | Valid call shape depends on overloads, generics, optional args, variadic args, and inferred receiver type. |
| **Solution**           | LSP computes current call context and returns matching signatures.                                         |
| **Typical tools**      | LSP `signatureHelp`, compiler services.                                                                    |
| **Relates to**         | Completion, diagnostics, type inspection.                                                                  |

**Pattern**

```text
cursor inside call → callable symbol → matching signature → active parameter
```

Signature help is a local version of type inspection.

---

# 20. Semantic tokens / highlighting

| Field                  | Description                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **Use case**           | “Color this code according to meaning, not regex.”                                                                             |
| **Conceptual problem** | Syntax highlighting sees text; semantic highlighting sees roles: function, type, enum, field, parameter, readonly, deprecated. |
| **Solution**           | LSP returns semantic token classifications.                                                                                    |
| **Typical tools**      | LSP `semanticTokens`, tree-sitter, compiler tokens.                                                                            |
| **Relates to**         | Readability, diagnostics, type inspection.                                                                                     |

**Pattern**

```text
source → parser/type model → semantic token stream
```

This is mostly display-oriented, but useful for human code review.

---

# 21. Call hierarchy

| Field                  | Description                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------------- |
| **Use case**           | “Who calls this function, and what does it call?”                                            |
| **Conceptual problem** | Reference search tells where a symbol appears, but not necessarily execution/call structure. |
| **Solution**           | Build caller/callee relationships from semantic analysis.                                    |
| **Typical tools**      | LSP `callHierarchy`, compiler graph.                                                         |
| **Relates to**         | Impact analysis, debugging, architecture understanding.                                      |

**Pattern**

```text
function → incoming calls / outgoing calls
```

**Difference from references**

```text
references = all semantic mentions
call hierarchy = executable call edges
```

---

# 22. Type hierarchy

| Field                  | Description                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Use case**           | “What implements this interface?”                                                           |
| **Conceptual problem** | Relationships between types may be implicit, structural, inherited, embedded, or generated. |
| **Solution**           | Use type checker to compute supertype/subtype/implementation relationships.                 |
| **Typical tools**      | LSP `typeHierarchy`, compiler APIs.                                                         |
| **Relates to**         | Refactor, codegen, architecture maps.                                                       |

**Pattern**

```text
type/interface → implementors/subtypes/supertypes
```

**Example**

```text
Adapter interface
→ WezTerm adapter
→ chezmoi adapter
→ git-ws adapter
→ MCP adapter
```

Type hierarchy is central when the architecture is adapter-heavy.

---

# 23. Test intelligence

| Field                  | Description                                                                             |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Use case**           | “Which tests cover this code?”                                                          |
| **Conceptual problem** | Tests are related by naming, imports, runtime behavior, coverage data, and conventions. |
| **Solution**           | Map code symbols/files to test files, test cases, coverage, and execution commands.     |
| **Typical tools**      | test explorer, coverage tools, compiler metadata, custom conventions.                   |
| **Relates to**         | Impact analysis, validation, agent repair loops.                                        |

**Pattern**

```text
changed code → related tests → run subset → diagnostics
```

**Example**

```text
sessionizer.lua changed
→ run project model tests
→ run WezTerm config load check
→ run manual-cd launch regression
```

Test intelligence closes the semantic-to-runtime loop.

---

# 24. Runtime probing

| Field                  | Description                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Use case**           | “Does this actually work when loaded?”                                                      |
| **Conceptual problem** | Static tooling cannot prove all runtime behavior.                                           |
| **Solution**           | Execute controlled probes: config load, dry run, smoke test, REPL eval, command invocation. |
| **Typical tools**      | `wezterm cli`, `nvim --headless`, `cue vet`, `go test`, custom probes.                      |
| **Relates to**         | Diagnostics, validation, contract checks, CI.                                               |

**Pattern**

```text
static pass → runtime probe → evidence
```

**Example**

```text
lua_ls says config is typed
stylua passes
wezterm start --config-file loads
actual keybinding behavior still needs runtime validation
```

Runtime probing is downstream of static code intelligence.

---

# 25. Agent-facing tool adapter

| Field                  | Description                                                               |
| ---------------------- | ------------------------------------------------------------------------- |
| **Use case**           | “Expose code intelligence to an agent over MCP or another tool protocol.” |
| **Conceptual problem** | Agents need structured, bounded operations instead of raw editor state.   |
| **Solution**           | Wrap LSP/compiler/indexer capabilities as tool calls with stable schemas. |
| **Typical tools**      | MCP, LSP bridge, custom RPC, JSON-RPC adapters.                           |
| **Relates to**         | VFS, symbol search, diagnostics, code actions, project graph.             |

**Pattern**

```text
agent request
→ tool schema
→ LSP/indexer/compiler operation
→ structured result
→ agent action
```

**Example MCP tools**

```text
code.symbols(workspace)
code.definition(uri, position)
code.references(uri, position)
code.diagnostics(uri)
code.hover(uri, position)
code.rename(uri, position, newName)
code.workspaceGraph()
code.validateContract()
```

This pattern converts editor-local intelligence into agent-operable intelligence.

---

# 26. Contract-first codegen

| Field                  | Description                                                                                                                |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “Generate implementation artifacts from a typed authority model.”                                                          |
| **Conceptual problem** | Handwritten code and config drift from the intended architecture.                                                          |
| **Solution**           | Keep contracts in a schema language, generate typed adapters/artifacts, then validate both generated and handwritten code. |
| **Typical tools**      | CUE, JSON Schema, code generators, Lua annotations, TypeScript declarations.                                               |
| **Relates to**         | Generated code intelligence, schema validation, VFS, MCP.                                                                  |

**Pattern**

```text
contract → projection → generated types/adapters → LSP validation → runtime probe
```

**Example**

```text
CUE dotfiles contract
→ generate Lua type stubs
→ lua_ls validates WezTerm config modules
→ MCP exposes contract and implementation graph
```

This is the highest-leverage pattern for typed dotfiles/control-plane work.

---

# 27. Provenance / evidence tracking

| Field                  | Description                                                                                                               |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “Why do we believe this code satisfies the contract?”                                                                     |
| **Conceptual problem** | A passing file is not enough; you need traceability from claim to artifact to validator result.                           |
| **Solution**           | Store evidence records linking contract nodes, source files, symbols, generated artifacts, diagnostics, and test results. |
| **Typical tools**      | CUE graph, JSON-LD, build logs, CI artifacts, custom evidence registry.                                                   |
| **Relates to**         | Contract validation, generated code, agent audit, CI.                                                                     |

**Pattern**

```text
claim → artifact → symbol → validator → result → timestamp/hash
```

**Example**

```json
{
  "claim": "wezterm.smart_splits adapter is typed",
  "artifact": "smart_splits.lua",
  "symbol": "smart_splits.apply_to_config",
  "validator": "lua_ls",
  "result": "pass"
}
```

Provenance turns code intelligence into auditable system intelligence.

---

# 28. Cross-language boundary mapping

| Field                  | Description                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------------- |
| **Use case**           | “How does this CUE model relate to Lua, shell, JSON, or generated files?”                                     |
| **Conceptual problem** | LSPs are usually language-local, but real systems cross language boundaries.                                  |
| **Solution**           | Define explicit boundary objects: generated files, adapter schemas, symbol maps, source maps, manifest edges. |
| **Typical tools**      | CUE, LSPs per language, VFS, custom graph index, MCP.                                                         |
| **Relates to**         | Contract-first codegen, dependency graph, validation.                                                         |

**Pattern**

```text
CUE node
→ generated JSON/Lua/type stub
→ Lua symbol
→ runtime command
→ evidence
```

**Example**

```text
CUE Project
→ git-ws manifest
→ WezTerm launcher entry
→ Neovim cwd/session
```

Cross-language mapping is where a project graph becomes more powerful than isolated LSPs.

---

# 29. Index cache / freshness management

| Field                  | Description                                                                                               |
| ---------------------- | --------------------------------------------------------------------------------------------------------- |
| **Use case**           | “Can I trust this code intelligence result?”                                                              |
| **Conceptual problem** | Indexes become stale when files change, generated artifacts update, dependencies install, or roots shift. |
| **Solution**           | Track file versions, hashes, invalidation rules, and rebuild boundaries.                                  |
| **Typical tools**      | LSP document versions, watchman, file watchers, compiler caches, custom cache keys.                       |
| **Relates to**         | VFS, generated code, diagnostics, agent safety.                                                           |

**Pattern**

```text
file/content hash → index entry → invalidation event → recompute
```

**Cache contract**

```text
input hash + tool version + config hash = valid intelligence result
```

This matters heavily for agents because stale intelligence causes wrong edits.

---

# 30. Capability discovery

| Field                  | Description                                                               |
| ---------------------- | ------------------------------------------------------------------------- |
| **Use case**           | “What can this language server/toolchain actually do?”                    |
| **Conceptual problem** | Different LSPs support different methods, extensions, and quality levels. |
| **Solution**           | Inspect server capabilities and test real behavior with probes.           |
| **Typical tools**      | LSP initialize result, health checks, smoke tests, fixture workspaces.    |
| **Relates to**         | MCP design, adapter planning, tool selection.                             |

**Pattern**

```text
tool starts → advertise capabilities → probe features → record support matrix
```

**Example capability matrix**

| Capability      |  lua_ls |        CUE LSP |                 gopls |
| --------------- | ------: | -------------: | --------------------: |
| diagnostics     |     yes |            yes |                   yes |
| completion      |     yes |            yes |                   yes |
| hover           |     yes |            yes |                   yes |
| references      |     yes | partial/varies |                   yes |
| rename          |     yes |         varies |                   yes |
| workspace graph | limited |        limited | strong via Go tooling |

Capability discovery should happen before designing MCP tools around an LSP.

---

# Relationship map

```text
workspace root
  ↓
filesystem / VFS
  ↓
parse / index
  ↓
symbols ───────→ references ───────→ rename
  ↓                  ↓                  ↓
definition       impact analysis     workspace edit
  ↓                  ↓                  ↓
types ─────────→ diagnostics ───────→ quick fix
  ↓                  ↓                  ↓
completion      validation           refactor
  ↓                  ↓                  ↓
docs/hover       tests/runtime        evidence
```

---

# Layered maturity model

## Level 0 — Text tools

```text
rg, fd, sed, grep
```

| Strength        | Weakness                  |
| --------------- | ------------------------- |
| Fast, universal | No semantic understanding |

Use for lexical discovery and fallback.

---

## Level 1 — Syntax tools

```text
tree-sitter, parser, formatter
```

| Strength                   | Weakness                                   |
| -------------------------- | ------------------------------------------ |
| Understands code structure | Does not fully understand types or imports |

Use for structural search, highlighting, codemods.

---

## Level 2 — Semantic tools

```text
LSP, compiler, type checker
```

| Strength                               | Weakness               |
| -------------------------------------- | ---------------------- |
| Understands symbols, types, references | Usually language-local |

Use for completion, diagnostics, rename, hover.

---

## Level 3 — Project graph

```text
workspace graph, dependency graph, generated artifacts, test mapping
```

| Strength                         | Weakness                 |
| -------------------------------- | ------------------------ |
| Understands system relationships | Requires custom modeling |

Use for impact analysis and architecture navigation.

---

## Level 4 — Contract graph

```text
CUE / JSON-LD / schema authority
```

| Strength                          | Weakness                         |
| --------------------------------- | -------------------------------- |
| Understands intended system shape | Needs adapters to implementation |

Use for policy validation, projection, provenance.

---

## Level 5 — Agent-operable intelligence

```text
MCP / structured code-intel tools / evidence registry
```

| Strength                       | Weakness                                         |
| ------------------------------ | ------------------------------------------------ |
| Agent can query and act safely | Needs constrained schemas and freshness controls |

Use for controlled automation.

---

# Practical pattern stack for your dotfiles direction

Given the project shape, the strong stack is:

```text
CUE contract model
→ generated JSON / Lua type artifacts
→ lua_ls over typed Lua implementation
→ CUE LSP over authority model
→ runtime probes: wezterm, nvim, cue vet
→ MCP adapter exposing bounded code-intel operations
→ evidence graph linking contract ↔ artifact ↔ symbol ↔ validation
```

## Minimal viable toolchain

| Layer           | Tool                               |
| --------------- | ---------------------------------- |
| Lexical search  | `rg`, `fd`                         |
| Syntax          | tree-sitter / StyLua / CUE fmt     |
| Lua semantics   | `lua_ls`                           |
| CUE semantics   | `cue lsp`, `cue vet`, `cue export` |
| Runtime probes  | `wezterm`, `nvim --headless`       |
| Agent bridge    | MCP tools                          |
| Authority model | CUE contract graph                 |

---

# Best pattern names to keep

| Pattern                | Core question                              |
| ---------------------- | ------------------------------------------ |
| Symbol discovery       | What exists?                               |
| Definition resolution  | Where did this come from?                  |
| Reference search       | Where is it used?                          |
| Type inspection        | What shape does it have?                   |
| Completion             | What is valid here?                        |
| Diagnostics            | What is wrong?                             |
| Code action            | What safe edit fixes it?                   |
| Refactor               | How do I change structure safely?          |
| Workspace root         | What project context applies?              |
| VFS overlay            | What content should tools see?             |
| Generated intelligence | Can generated artifacts be indexed?        |
| Schema validation      | Does this satisfy the contract?            |
| Dependency graph       | What depends on what?                      |
| Impact analysis        | What changes if this changes?              |
| Runtime probe          | Does it actually work?                     |
| MCP adapter            | How does an agent use this safely?         |
| Evidence tracking      | Why do we trust the result?                |
| Cross-language mapping | How do models and implementations connect? |
| Freshness management   | Is the result still valid?                 |
| Capability discovery   | What can this tool really do?              |
