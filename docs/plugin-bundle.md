
# Yes: single bundle is the right unit

The practical shape is:

```text
contract-agent-runtime/
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

This is effectively a **packaged agent runtime model**:

```text
Bundle
  = installable runtime package

MCP server
  = controller / actuator / evidence channel

Skills
  = model-facing workflow adapters

CUE contracts
  = authority / policy / graph / validation

openai.yaml
  = Codex/OpenAI-specific metadata adapter

references/
  = projected human-readable contract docs
```

---

# Correct abstraction

```text
AgentRuntimeBundle
  ├── RuntimeManifest
  ├── MCPServer
  ├── WorkflowSkills
  │     ├── resolve-agent-context
  │     ├── vcs
  │     └── code-intel
  ├── ContractReferences
  └── RuntimeAdapters
```

Not:

```text
VCS plugin
Code-intel plugin
Context plugin
```

Better:

```text
contract-agent-runtime plugin
  contains workflow surfaces
```

Because these three surfaces are not independent. They share:

```text
projection_id
evidence_id
provider_id
artifact_id
validation_id
authority plane
backend adapters
turn lifecycle
```

---

# Runtime control loop

```text
User prompt
  ↓
resolve-agent-context skill
  ↓
contract MCP: context.resolve
  ↓
projection_id
  ↓
workflow skill selected
  ├── vcs
  └── code-intel
  ↓
contract MCP workflow command group
  ↓
CUE validation
  ↓
backend adapter execution
  ↓
evidence/result
  ↓
agent response with cited evidence
```

The single-bundle invariant is:

```text
All workflow skills share the same authority graph and MCP result model.
```

---

# Bundle-level schema

```cue
#AgentRuntimeBundle: {
	name: "contract-agent-runtime"
	version: string

	manifest: ".codex-plugin/plugin.json"
	mcp: ".mcp.json"

	skills: {
		"resolve-agent-context": #WorkflowSkill & {
			role: "context-router"
			commandGroup: "context.*"
		}

		vcs: #WorkflowSkill & {
			role: "mutation-transaction"
			commandGroup: "stack.*" | "evidence.*"
		}

		"code-intel": #WorkflowSkill & {
			role: "implementation-evidence"
			commandGroup: "codeIntel.*" | "projection.*" | "symbol.*"
		}
	}

	authority: {
		source: "contract.cuemod"
		graph: true
		mcpResultSchema: true
		validation: true
	}

	runtime: {
		mcpServer: "contract"
		rawBackendAccess: false
	}
}

#WorkflowSkill: {
	role: string
	commandGroup: string | [...string]

	thin: true

	owns: [
		"trigger description",
		"workflow procedure",
		"sequencing obligations",
		"forbidden direct access",
		"evidence obligations",
	]

	doesNotOwn: [
		"backend implementation",
		"state mutation",
		"raw VCS",
		"raw CUE",
		"raw LSP",
		"validation authority",
	]
}
```

---

# Plugin manifest sketch

```json
{
  "name": "contract-agent-runtime",
  "version": "0.1.0",
  "description": "CUE-backed agent runtime for context resolution, VCS patch transactions, code intelligence, validation, and evidence.",
  "skills": "./skills",
  "mcpServers": "./.mcp.json",
  "interface": {
    "displayName": "Contract Agent Runtime",
    "shortDescription": "CUE-backed workflow runtime for safe agent operations",
    "developerName": "fatb4f",
    "category": "Developer Tools",
    "capabilities": [
      "Code intelligence",
      "Version control",
      "Evidence",
      "Validation"
    ],
    "defaultPrompt": [
      "Resolve contract context before inspecting or editing this repository.",
      "Use the contract runtime for patch staging, evidence, validation, and finalization.",
      "Use code-intel workflow tools for symbol, implementation, and diagnostic evidence."
    ]
  }
}
```

---

# MCP server sketch

```json
{
  "mcpServers": {
    "contract": {
      "command": "contract-mcp",
      "args": ["serve", "--stdio"],
      "env": {
        "CONTRACT_ROOT": "${workspaceFolder}"
      }
    }
  }
}
```

The public MCP surface should be grouped like this:

```text
context.*
  context.resolve
  context.inspectProjection

stack.*
  stack.status
  stack.startPatch
  stack.activatePatch
  stack.stage
  stack.prepareEvidence
  stack.finalizePatch
  stack.push
  stack.rollback
  stack.compareRevision

codeIntel.*
  codeIntel.resolve
  codeIntel.searchImplementation
  codeIntel.definition
  codeIntel.references
  codeIntel.diagnostics
  codeIntel.validate

evidence.*
  evidence.prepare
  evidence.record
  evidence.seal
  evidence.inspect

validation.*
  validation.run
  validation.inspect
```

Private backend namespaces remain hidden:

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

---

# Skill layout

## `skills/resolve-agent-context/SKILL.md`

Purpose:

```text
Convert user prompt + cwd + hook candidates into authoritative projection_id.
```

Owns:

```text
resolve first
do not trust hook candidates as authority
retain projection_id
use projection for later VCS/code-intel calls
```

## `skills/vcs/SKILL.md`

Purpose:

```text
Operate patch-stack lifecycle through contract MCP tools.
```

Owns:

```text
transaction sequencing
stage/evidence/finalize/push lifecycle
rollback obligation
forbidden raw git
evidence/citation obligation
turn-completion rules
```

## `skills/code-intel/SKILL.md`

Purpose:

```text
Resolve implementation context, symbols, references, diagnostics, and validation evidence.
```

Owns:

```text
use projection_id
search implementation through MCP
cite evidence IDs
avoid raw rg/cue/lsp unless exposed by contract MCP
validate through contract tools
```

---

# Why one bundle is better

## Shared authority

```text
resolve-agent-context produces projection_id.
vcs consumes projection_id for patch scope and evidence.
code-intel consumes projection_id for implementation/symbol evidence.
validation consumes projection_id/evidence_id.
```

Splitting them into separate plugins would force artificial synchronization across package boundaries.

## Shared evidence model

```text
VCS evidence and code-intel evidence are the same class of graph output.
```

Both should produce:

```text
provider_id
projection_id
artifact_id
symbol_id?
evidence_id
claim
diagnostics?
```

## Shared safety policy

The same constraints apply across workflows:

```text
no raw backend access
no uncited complete claims
no mutation without transaction
no finalization without evidence
no validation bypass
```

---

# Better naming

Avoid naming the bundle after a single workflow:

```text
Bad:
  vcs-plugin
  code-intel-plugin

Better:
  contract-agent-runtime
  contract-workflow-runtime
  contract-agent-pack
  contract-codex-runtime
```

Given your repo language, strongest name:

```text
contract-agent-runtime
```

---

# Final pattern

```text
One bundle.
One MCP server.
Three thin workflow skills.
One shared CUE authority graph.
One shared evidence/result schema.
One OpenAI adapter layer per skill.
```

Compact invariant:

```text
The bundle packages the runtime.
The MCP server executes the runtime.
The skills route the model into the runtime.
CUE decides what is legal.
Evidence proves what happened.
```
