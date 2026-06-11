
# Initial scope: MCP code-intel v0

## Scope lock

```text
single MCP server
├── CUE CLI wrappers
├── rg wrappers
├── CUE LSP adapter
├── LuaLS adapter
├── contract registry
├── policy gate
└── evidence ledger
```

**Mode:** read/analysis-only.

No patching, no formatting writes, no shell escape, no generated-file materialization yet.

MCP is the outer protocol projection: servers expose resources, tools, and prompts; clients can provide roots and related client capabilities. ([Model Context Protocol][1]) CUE modules use `cue.mod/module.cue`, and modern CUE expects a `language.version` field there. ([CUE][2]) CUE has CLI subcommands such as `export`, `eval`, and `vet`, and CUE LSP support is now exposed through the CUE toolchain / `cuepls` path. ([CUE][3]) LuaLS is an LSP-based Lua language server, with `lua-language-server` as the command-line entrypoint. ([Lua Language Server][4])

---

# 1. Proposed seed layout

```text
contract.cuemod/
├── cue.mod/
│   └── module.cue
├── contract/
│   ├── schema.cue
│   ├── primitives.cue
│   ├── adapters.cue
│   ├── tools.cue
│   ├── workflows.cue
│   └── policy.cue
└── spec/
    └── mcp-code-intel-server.md
```

---

# 2. `contract.cuemod/cue.mod/module.cue`

```cue
module: "github.com/fatb4f/dotfiles/contract"
language: version: "v0.14.0"
```

Adjust `language.version` to the local `cue` toolchain version.

---

# 3. `contract.cuemod/contract/schema.cue`

```cue
package contract

#Id: =~"^[a-z][a-z0-9_.-]*$"

#Risk: "read" | "analysis" | "write" | "exec" | "network"

#Authority:
	"authoritative" |
	"derived" |
	"heuristic" |
	"projection" |
	"fallback"

#Rationale: {
	problem: string
	why:     string
	nonGoals?: [...string]
	tradeoffs?: [...string]
}

#EvidenceRef: {
	id:     #Id
	source: string
	kind:   "tool-output" | "lsp-result" | "cli-output" | "file-hash" | "diagnostic" | "policy-decision"
}

#FailureMode: {
	id:          #Id
	description: string
	recoverable: bool | *true
}

#Port: {
	name:        string
	description: string
	schema?:     string
}

#Contract: {
	inputs:        [...#Port]
	outputs:       [...#Port]
	preconditions: [...string]
	postconditions: [...string]
	invariants:    [...string]
	failureModes:  [...#FailureMode]
	evidence:      [...#EvidenceRef] | *[]
}

#Component: {
	id:   #Id
	kind: "mcp-server" | "adapter" | "tool" | "resource" | "workflow" | "policy" | "evidence"

	rationale: #Rationale
	contract:  #Contract
}

#Adapter: #Component & {
	kind: "adapter"

	authority: #Authority

	process?: {
		command: [...string]
		cwd?:    string
		env?:    [string]: string
	}

	capabilities: [...string]
}

#Tool: #Component & {
	kind: "tool"

	risk: #Risk

	exec: {
		adapter: #Id
		command: [...string]
		timeoutMs: int | *10000
	}

	idempotent: bool | *true
	requiresApproval: bool | *false
}

#Resource: #Component & {
	kind: "resource"

	uri: string
	cacheable: bool | *true
	snapshotScoped: bool | *true
}

#Workflow: #Component & {
	kind: "workflow"

	mode: "observe" | "analyze" | "validate" | "plan"

	phases: [...{
		id: #Id
		entry: [...string]
		actions: [...#Id]
		exit: [...string]
	}]
}
```

---

# 4. `contract.cuemod/contract/primitives.cue`

```cue
package contract

primitives: {
	mcp: #Component & {
		id:   "primitive.mcp"
		kind: "mcp-server"

		rationale: {
			problem: "Agents need one bounded integration surface for code-intel context and analysis tools."
			why:     "MCP projects contract-backed tools, resources, and workflows to the agent."
			nonGoals: [
				"MCP is not the source of truth.",
				"MCP does not own language semantics.",
				"MCP does not bypass policy.",
			]
		}

		contract: {
			inputs: [
				{name: "mcp-request", description: "JSON-RPC request from client"},
				{name: "roots", description: "Client-provided workspace roots"},
				{name: "capability-registry", description: "Declared resources, tools, prompts"},
			]
			outputs: [
				{name: "mcp-response", description: "Contract-shaped result or error"},
				{name: "evidence", description: "Evidence records for nontrivial claims"},
			]
			preconditions: [
				"server initialized",
				"capabilities registered",
				"policy loaded",
			]
			postconditions: [
				"all tool calls are policy-checked",
				"all results identify adapter authority where applicable",
			]
			invariants: [
				"no uncontracted capability is exposed",
				"no write tool is exposed in v0",
				"every adapter has rationale and contract",
			]
			failureModes: [
				{id: "mcp.unknown-capability", description: "Requested capability is not registered"},
				{id: "mcp.policy-denied", description: "Policy rejected the requested operation"},
				{id: "mcp.adapter-unavailable", description: "Required backend adapter is unavailable"},
			]
		}
	}

	lsp: #Component & {
		id:   "primitive.lsp"
		kind: "adapter"

		rationale: {
			problem: "Agents need language-aware facts without reimplementing CUE or Lua semantics."
			why:     "LSP delegates symbols, diagnostics, definitions, references, hover, and workspace facts to language servers."
			nonGoals: [
				"LSP is not the contract authority.",
				"LSP results are not automatically trusted without snapshot and evidence metadata.",
			]
		}

		contract: {
			inputs: [
				{name: "workspace-root", description: "Normalized root for language server"},
				{name: "document-uri", description: "LSP document URI"},
				{name: "method", description: "Requested LSP method"},
			]
			outputs: [
				{name: "diagnostics", description: "Language diagnostics"},
				{name: "symbols", description: "Document or workspace symbols"},
				{name: "locations", description: "Definition/reference/declaration locations"},
				{name: "hover", description: "Hover information"},
			]
			preconditions: [
				"language server process available",
				"workspace root permitted by policy",
			]
			postconditions: [
				"results are tagged with language server identity",
				"results are tagged with document snapshot identity",
			]
			invariants: [
				"LSP facts are derived evidence, not primary contract authority",
				"partial results must be marked as partial",
			]
			failureModes: [
				{id: "lsp.server-unavailable", description: "Language server cannot be started"},
				{id: "lsp.unsupported-method", description: "Requested LSP method is unsupported"},
				{id: "lsp.timeout", description: "LSP method timed out"},
			]
		}
	}
}
```

---

# 5. `contract.cuemod/contract/adapters.cue`

```cue
package contract

adapters: {
	cueCli: #Adapter & {
		id: "adapter.cue-cli"

		rationale: {
			problem: "Agents need bounded access to CUE validation and export behavior."
			why:     "The CUE CLI is the local authority for evaluating and validating CUE contracts."
			nonGoals: [
				"Do not expose arbitrary cue subcommands.",
				"Do not expose commands that mutate files in v0.",
			]
		}

		authority: "authoritative"

		process: {
			command: ["cue"]
		}

		capabilities: [
			"cue.version",
			"cue.eval",
			"cue.export",
			"cue.vet",
		]

		contract: {
			inputs: [
				{name: "args", description: "Allowlisted CUE command arguments"},
				{name: "cwd", description: "Workspace root or contract.cuemod root"},
			]
			outputs: [
				{name: "stdout", description: "Command stdout"},
				{name: "stderr", description: "Command stderr"},
				{name: "exit-code", description: "Process exit code"},
			]
			preconditions: [
				"cue binary exists",
				"cwd is inside allowed root",
				"subcommand is allowlisted",
			]
			postconditions: [
				"no files are modified",
				"output is captured as evidence",
			]
			invariants: [
				"no shell interpolation",
				"no write flags",
				"no unbounded path traversal",
			]
			failureModes: [
				{id: "cue.missing-binary", description: "cue executable not found"},
				{id: "cue.invalid-args", description: "arguments rejected by wrapper policy"},
				{id: "cue.nonzero", description: "cue returned nonzero exit code"},
			]
		}
	}

	rg: #Adapter & {
		id: "adapter.rg"

		rationale: {
			problem: "Agents need fast bounded text/file search."
			why:     "rg is the low-level repo search sensor for locating files, symbols, and contract fragments."
			nonGoals: [
				"Do not expose arbitrary shell commands.",
				"Do not allow searches outside workspace roots.",
			]
		}

		authority: "derived"

		process: {
			command: ["rg"]
		}

		capabilities: [
			"rg.search",
			"rg.files",
		]

		contract: {
			inputs: [
				{name: "pattern", description: "Search pattern"},
				{name: "glob", description: "Optional allowlisted glob"},
				{name: "root", description: "Allowed workspace root"},
			]
			outputs: [
				{name: "matches", description: "Bounded match set"},
				{name: "files", description: "Bounded file list"},
			]
			preconditions: [
				"rg binary exists",
				"root is allowed",
				"result limit is set",
			]
			postconditions: [
				"results include file path and line span",
				"results are bounded by max count",
			]
			invariants: [
				"search never escapes workspace root",
				"binary files are excluded unless explicitly allowed later",
			]
			failureModes: [
				{id: "rg.missing-binary", description: "rg executable not found"},
				{id: "rg.no-results", description: "search completed with no results"},
				{id: "rg.too-many-results", description: "result limit reached"},
			]
		}
	}

	cueLsp: #Adapter & {
		id: "adapter.cue-lsp"

		rationale: {
			problem: "Agents need CUE-aware language intelligence over contract files."
			why:     "CUE LSP exposes diagnostics, symbols, hover, and navigation for CUE packages."
			nonGoals: [
				"Do not use CUE LSP as replacement for cue CLI validation.",
				"Do not rely on editor-only state.",
			]
		}

		authority: "derived"

		process: {
			command: ["cuepls"]
		}

		capabilities: [
			"lsp.initialize",
			"textDocument/diagnostic",
			"textDocument/documentSymbol",
			"textDocument/definition",
			"textDocument/references",
			"textDocument/hover",
			"workspace/symbol",
		]

		contract: {
			inputs: [
				{name: "root", description: "contract.cuemod or workspace root"},
				{name: "document-uri", description: "CUE document URI"},
				{name: "position", description: "Optional LSP position"},
			]
			outputs: [
				{name: "diagnostics", description: "CUE LSP diagnostics"},
				{name: "symbols", description: "CUE symbols"},
				{name: "locations", description: "Definitions and references"},
				{name: "hover", description: "Hover payload"},
			]
			preconditions: [
				"cue LSP command available",
				"document path is under allowed root",
			]
			postconditions: [
				"LSP result includes server identity",
				"LSP result includes document snapshot identity",
			]
			invariants: [
				"CUE CLI validation remains authoritative",
				"LSP output is analysis evidence",
			]
			failureModes: [
				{id: "cue-lsp.unavailable", description: "CUE LSP process unavailable"},
				{id: "cue-lsp.unsupported", description: "method unsupported by server"},
				{id: "cue-lsp.timeout", description: "request timed out"},
			]
		}
	}

	luaLs: #Adapter & {
		id: "adapter.lua-ls"

		rationale: {
			problem: "Agents need typed Lua intelligence for Neovim, WezTerm, and shared Lua modules."
			why:     "LuaLS exposes Lua diagnostics, symbols, hover, definitions, references, and type information."
			nonGoals: [
				"Do not execute Lua code.",
				"Do not treat annotations as runtime validation.",
			]
		}

		authority: "derived"

		process: {
			command: ["lua-language-server"]
		}

		capabilities: [
			"lsp.initialize",
			"textDocument/diagnostic",
			"textDocument/documentSymbol",
			"textDocument/definition",
			"textDocument/references",
			"textDocument/hover",
			"workspace/symbol",
		]

		contract: {
			inputs: [
				{name: "root", description: "Lua project root"},
				{name: "document-uri", description: "Lua document URI"},
				{name: "position", description: "Optional LSP position"},
			]
			outputs: [
				{name: "diagnostics", description: "LuaLS diagnostics"},
				{name: "symbols", description: "Lua symbols"},
				{name: "locations", description: "Definitions and references"},
				{name: "hover", description: "Hover/type payload"},
			]
			preconditions: [
				"lua-language-server available",
				"document path is under allowed root",
			]
			postconditions: [
				"LSP result includes server identity",
				"LSP result includes document snapshot identity",
			]
			invariants: [
				"LuaLS is static analysis only",
				"Lua code is not executed",
			]
			failureModes: [
				{id: "lua-ls.unavailable", description: "LuaLS process unavailable"},
				{id: "lua-ls.unsupported", description: "method unsupported by server"},
				{id: "lua-ls.timeout", description: "request timed out"},
			]
		}
	}
}
```

---

# 6. `contract.cuemod/contract/tools.cue`

```cue
package contract

tools: {
	cueVersion: #Tool & {
		id:   "tool.cue.version"
		risk: "read"

		rationale: {
			problem: "Agent needs to know the active CUE toolchain."
			why:     "CUE behavior and module language version depend on the installed toolchain."
		}

		exec: {
			adapter: "adapter.cue-cli"
			command: ["cue", "version"]
		}

		contract: adapters.cueCli.contract
	}

	cueEval: #Tool & {
		id:   "tool.cue.eval"
		risk: "analysis"

		rationale: {
			problem: "Agent needs evaluated CUE values without modifying files."
			why:     "cue eval is the primary read-side evaluator for contract inspection."
			nonGoals: ["No file writes", "No import generation"]
		}

		exec: {
			adapter: "adapter.cue-cli"
			command: ["cue", "eval"]
		}

		contract: adapters.cueCli.contract
	}

	cueExport: #Tool & {
		id:   "tool.cue.export"
		risk: "analysis"

		rationale: {
			problem: "Agent needs concrete JSON/YAML export from CUE."
			why:     "Exported concrete data can feed MCP manifests and validation reports."
			nonGoals: ["No writing exported output to disk in v0"]
		}

		exec: {
			adapter: "adapter.cue-cli"
			command: ["cue", "export"]
		}

		contract: adapters.cueCli.contract
	}

	cueVet: #Tool & {
		id:   "tool.cue.vet"
		risk: "analysis"

		rationale: {
			problem: "Agent needs schema validation over data and contracts."
			why:     "cue vet is the validation gate for contract and data conformance."
			nonGoals: ["No automatic repair"]
		}

		exec: {
			adapter: "adapter.cue-cli"
			command: ["cue", "vet"]
		}

		contract: adapters.cueCli.contract
	}

	rgSearch: #Tool & {
		id:   "tool.rg.search"
		risk: "read"

		rationale: {
			problem: "Agent needs bounded content search."
			why:     "rg.search is the low-cost sensor for finding declarations, contracts, TODOs, and evidence."
		}

		exec: {
			adapter: "adapter.rg"
			command: ["rg", "--line-number", "--column", "--max-count", "200"]
		}

		contract: adapters.rg.contract
	}

	rgFiles: #Tool & {
		id:   "tool.rg.files"
		risk: "read"

		rationale: {
			problem: "Agent needs bounded file discovery."
			why:     "rg.files gives the agent an allowlisted workspace inventory without broad filesystem access."
		}

		exec: {
			adapter: "adapter.rg"
			command: ["rg", "--files"]
		}

		contract: adapters.rg.contract
	}

	cueLspQuery: #Tool & {
		id:   "tool.cue-lsp.query"
		risk: "analysis"

		rationale: {
			problem: "Agent needs CUE language-server facts."
			why:     "CUE LSP query wraps a constrained subset of LSP methods."
		}

		exec: {
			adapter: "adapter.cue-lsp"
			command: ["lsp", "request"]
			timeoutMs: 15000
		}

		contract: adapters.cueLsp.contract
	}

	luaLsQuery: #Tool & {
		id:   "tool.lua-ls.query"
		risk: "analysis"

		rationale: {
			problem: "Agent needs Lua language-server facts."
			why:     "LuaLS query wraps a constrained subset of LSP methods."
		}

		exec: {
			adapter: "adapter.lua-ls"
			command: ["lsp", "request"]
			timeoutMs: 15000
		}

		contract: adapters.luaLs.contract
	}
}
```

---

# 7. `contract.cuemod/contract/policy.cue`

```cue
package contract

policy: {
	mode: "read-analysis-only"

	allowedRisk: [
		"read",
		"analysis",
	]

	deniedRisk: [
		"write",
		"exec",
		"network",
	]

	allowedTools: [
		"tool.cue.version",
		"tool.cue.eval",
		"tool.cue.export",
		"tool.cue.vet",
		"tool.rg.search",
		"tool.rg.files",
		"tool.cue-lsp.query",
		"tool.lua-ls.query",
	]

	deniedCommands: [
		"cue fmt",
		"cue fix",
		"cue import",
		"cue mod tidy",
		"rm",
		"mv",
		"cp",
		"chmod",
		"git commit",
		"git reset",
	]

	invariants: [
		"no writes in v0",
		"no shell interpolation",
		"all command args are argv arrays",
		"all paths resolve under allowed roots",
		"all nontrivial results emit evidence",
	]
}
```

---

# 8. `contract.cuemod/contract/workflows.cue`

```cue
package contract

workflows: {
	agentAnalyze: #Workflow & {
		id:   "workflow.agent.analyze"
		mode: "analyze"

		rationale: {
			problem: "Agent needs a repeatable mode for code-intel inspection."
			why:     "Workflow phases constrain tool use and prevent exploratory tool sprawl."
			nonGoals: [
				"No patching",
				"No materialization",
				"No unconstrained shell access",
			]
		}

		phases: [
			{
				id: "observe"
				entry: [
					"workspace root known",
					"policy loaded",
				]
				actions: [
					"tool.rg.files",
					"tool.cue.version",
				]
				exit: [
					"file inventory available",
					"CUE toolchain known",
				]
			},
			{
				id: "inspect"
				entry: [
					"target files identified",
				]
				actions: [
					"tool.rg.search",
					"tool.cue-lsp.query",
					"tool.lua-ls.query",
				]
				exit: [
					"symbols and references collected",
					"diagnostics collected",
				]
			},
			{
				id: "validate"
				entry: [
					"CUE contract files identified",
				]
				actions: [
					"tool.cue.eval",
					"tool.cue.vet",
					"tool.cue.export",
				]
				exit: [
					"CUE validation result captured",
					"evidence records produced",
				]
			},
			{
				id: "report"
				entry: [
					"evidence records available",
				]
				actions: []
				exit: [
					"agent answer cites evidence",
					"unverified claims marked as assumptions",
				]
			},
		]

		contract: {
			inputs: [
				{name: "task", description: "Agent analysis task"},
				{name: "roots", description: "Allowed workspace roots"},
			]
			outputs: [
				{name: "answer", description: "Evidence-backed answer"},
				{name: "evidence", description: "Collected tool outputs and diagnostics"},
			]
			preconditions: [
				"policy.mode == read-analysis-only",
				"all required adapters healthy",
			]
			postconditions: [
				"no workspace mutation occurred",
				"answer separates facts from assumptions",
			]
			invariants: policy.invariants
			failureModes: [
				{id: "workflow.insufficient-evidence", description: "Required evidence could not be collected"},
				{id: "workflow.adapter-failed", description: "Required adapter failed"},
				{id: "workflow.policy-blocked", description: "Requested action exceeded v0 policy"},
			]
		}
	}
}
```

---

# 9. `contract.cuemod/spec/mcp-code-intel-server.md`

````md
# MCP Code-Intel Server v0

## 1. Purpose

The MCP code-intel server exposes a bounded, contract-backed code intelligence surface to agents.

The server is not the source of truth. The source of truth is the contract graph under `contract.cuemod`.

## 2. Initial scope

Included:

- single MCP server
- CUE CLI wrappers
- rg wrappers
- CUE LSP adapter
- LuaLS adapter
- contract registry
- policy gate
- evidence ledger
- agent workflow mode

Excluded:

- file mutation
- patch application
- generated artifact materialization
- arbitrary shell execution
- network tools
- package installation
- git writes
- formatter writes

## 3. Server implementation

### 3.1 Runtime shape

```text
agent/client
  -> MCP server
    -> capability registry
    -> policy gate
    -> adapter router
      -> cue CLI adapter
      -> rg adapter
      -> CUE LSP adapter
      -> LuaLS adapter
    -> evidence ledger
````

### 3.2 Required server responsibilities

The server must:

1. load contracts from `contract.cuemod`;
2. validate exposed tools against contract schemas;
3. expose only allowlisted tools;
4. reject write/exec/network risk classes in v0;
5. normalize workspace roots;
6. constrain all paths to allowed roots;
7. capture stdout/stderr/exit codes for CLI wrappers;
8. tag LSP results with server identity and document snapshot;
9. emit evidence records for all nontrivial operations.

### 3.3 Capability projection

Each MCP tool must be projected from a CUE `#Tool`.

Each MCP resource must be projected from a CUE `#Resource`.

Each workflow prompt must be projected from a CUE `#Workflow`.

No direct hand-written MCP capability should exist without a contract entry.

## 4. Exposed tool sets

### 4.1 CUE CLI tools

#### `cue.version`

Purpose:

* discover active CUE toolchain

Allowed command:

```text
cue version
```

Risk:

```text
read
```

#### `cue.eval`

Purpose:

* evaluate CUE contract values
* inspect contract graph state

Allowed command shape:

```text
cue eval <allowlisted args> <allowlisted paths>
```

Risk:

```text
analysis
```

Denied:

```text
-w
--out
file writes
shell interpolation
```

#### `cue.export`

Purpose:

* export concrete CUE data to stdout
* generate MCP manifest data in-memory

Allowed command shape:

```text
cue export <allowlisted args> <allowlisted paths>
```

Risk:

```text
analysis
```

Denied:

```text
writing export output to disk
```

#### `cue.vet`

Purpose:

* validate contracts and data against schemas

Allowed command shape:

```text
cue vet <allowlisted args> <allowlisted paths>
```

Risk:

```text
analysis
```

### 4.2 rg tools

#### `rg.search`

Purpose:

* bounded text search

Allowed command shape:

```text
rg --line-number --column --max-count 200 <pattern> <root/glob>
```

Risk:

```text
read
```

Constraints:

* root must be allowlisted
* result count must be bounded
* binary files excluded
* hidden files require explicit allowlist

#### `rg.files`

Purpose:

* bounded file inventory

Allowed command shape:

```text
rg --files <root>
```

Risk:

```text
read
```

Constraints:

* root must be allowlisted
* ignore policy respected unless explicitly overridden later

### 4.3 CUE LSP tools

#### `cue-lsp.query`

Purpose:

* request CUE language intelligence through a constrained LSP method set

Allowed methods:

```text
initialize
textDocument/diagnostic
textDocument/documentSymbol
textDocument/definition
textDocument/references
textDocument/hover
workspace/symbol
```

Risk:

```text
analysis
```

Constraints:

* document URI must resolve under allowed root
* results are derived evidence
* CUE CLI validation remains authoritative

### 4.4 LuaLS tools

#### `lua-ls.query`

Purpose:

* request Lua language intelligence through a constrained LSP method set

Allowed methods:

```text
initialize
textDocument/diagnostic
textDocument/documentSymbol
textDocument/definition
textDocument/references
textDocument/hover
workspace/symbol
```

Risk:

```text
analysis
```

Constraints:

* document URI must resolve under allowed root
* Lua code is never executed
* LuaLS output is static-analysis evidence

## 5. Agent workflow mode

The initial agent workflow mode is:

```text
read-analysis-only
```

### 5.1 Phase model

```text
observe -> inspect -> validate -> report
```

### 5.2 Observe

Allowed tools:

* `rg.files`
* `cue.version`

Goal:

* determine available files and toolchain version

Exit criteria:

* workspace inventory exists
* CUE version known

### 5.3 Inspect

Allowed tools:

* `rg.search`
* `cue-lsp.query`
* `lua-ls.query`

Goal:

* collect symbols, diagnostics, references, definitions, hover/type facts

Exit criteria:

* relevant symbols and diagnostics collected
* missing facts marked as unknown

### 5.4 Validate

Allowed tools:

* `cue.eval`
* `cue.vet`
* `cue.export`

Goal:

* validate contract graph
* export concrete manifest projections if needed

Exit criteria:

* validation result captured
* evidence records produced

### 5.5 Report

Allowed tools:

* none by default

Goal:

* answer using collected evidence
* separate facts, assumptions, and unresolved items

Exit criteria:

* final response is evidence-backed
* unverified claims are clearly marked

## 6. Policy

The v0 server must deny:

* all write operations
* arbitrary shell commands
* network access
* package installation
* git mutation
* formatter writes
* code execution through Lua
* file materialization

The v0 server may allow:

* bounded file search
* bounded CUE evaluation
* bounded CUE validation
* bounded LSP queries
* stdout-only export

## 7. Evidence model

Each tool result must include:

```json
{
  "tool": "tool id",
  "adapter": "adapter id",
  "authority": "authoritative | derived | heuristic | projection | fallback",
  "root": "workspace root",
  "inputsHash": "hash of normalized inputs",
  "stdout": "...",
  "stderr": "...",
  "exitCode": 0,
  "timestamp": "...",
  "diagnostics": []
}
```

## 8. v0 success criteria

The implementation is successful when:

1. MCP server starts.
2. Contract registry loads from `contract.cuemod`.
3. `cue version` works through MCP.
4. `rg --files` works through MCP.
5. `cue eval ./...` works through MCP.
6. `cue vet` works through MCP on at least one schema/data pair.
7. CUE LSP initializes and returns diagnostics or symbols.
8. LuaLS initializes and returns diagnostics or symbols.
9. Denied commands are rejected by policy.
10. Every tool result emits evidence metadata.

````

---

# 10. Initial invariant

```text
MCP capability
  must be projected from
CUE contract
  routed through
policy gate
  executed by
named adapter
  producing
evidence-tagged result
````

That is the seed. Everything else can extend from it without changing the control model.

[1]: https://modelcontextprotocol.io/specification/2025-11-25?utm_source=chatgpt.com "Specification"
[2]: https://cuelang.org/docs/reference/modules/?utm_source=chatgpt.com "CUE Modules"
[3]: https://cuelang.org/docs/reference/command/?utm_source=chatgpt.com "The cue command"
[4]: https://luals.github.io/?utm_source=chatgpt.com "Lua Language Server | Home"
