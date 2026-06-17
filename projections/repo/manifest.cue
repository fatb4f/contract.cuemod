package repo

import repocontract "github.com/fatb4f/contract.cuemod/contracts/repo:repo"

manifest: repocontract.#RepoLayout & {
	module: "github.com/fatb4f/contract.cuemod"

	surfaces: [
		{path: "contracts/", kind: "directory", role: "authority", lifecycle: "source", authority: "authoritative", generated: false, owner: "contracts/repo", description: "The repository's only contract authority root.", allowedExtensions: [".cue"], validatesWith: ["cue vet ./contracts/..."]},
		{path: "providers/", kind: "directory", role: "provider", lifecycle: "source", authority: "authoritative", generated: false, owner: "contracts/providers", description: "Concrete provider declarations.", allowedExtensions: [".cue"], validatesWith: ["cue vet ./providers/..."]},
		{path: "adapters/", kind: "directory", role: "adapter", lifecycle: "source", authority: "non-authority", generated: false, owner: "contracts/adapters", description: "Declarative references to external adapter sources.", allowedExtensions: [".cue"], forbiddenChildren: [".git"], validatesWith: ["cue vet ./adapters/git-mcp-go"]},
		{path: "projections/", kind: "directory", role: "projection", lifecycle: "source", authority: "derived", generated: false, owner: "contracts/repo", description: "Bounded views derived from contracts.", allowedExtensions: [".cue"], validatesWith: ["cue vet ./projections/..."]},
		{path: "fixtures/", kind: "directory", role: "fixture", lifecycle: "test-fixture", authority: "non-authority", generated: false, owner: "contracts/validation", description: "Assertion-derived valid and invalid evidence.", validatesWith: ["cue vet ./contracts/assertions"]},
		{path: "test/", kind: "directory", role: "validation", lifecycle: "source", authority: "non-authority", generated: false, owner: "contracts/validation", description: "Optional evaluator shims derived from assertions.", validatesWith: ["cue vet ./contracts/assertions"]},
		{path: "docs/", kind: "directory", role: "documentation", lifecycle: "source", authority: "non-authority", generated: false, owner: "contracts/repo", description: "Explanatory non-authority documentation.", allowedExtensions: [".md"], validatesWith: ["cue vet ./contracts/assertions"]},
		{path: ".github/", kind: "directory", role: "documentation", lifecycle: "source", authority: "non-authority", generated: false, owner: "contracts/repo", description: "GitHub repository metadata and contribution templates.", allowedExtensions: [".yml", ".yaml", ".md"], validatesWith: ["cue vet ./contracts/assertions"]},
		{path: ".repo/", kind: "directory", role: "generated", lifecycle: "generated", authority: "derived", generated: true, owner: "projections/repo", description: "Generated repository manifest and inventory.", validatesWith: ["cue vet ./contracts/assertions"]},
		{path: "cue.mod/", kind: "directory", role: "tooling", lifecycle: "source", authority: "authoritative", generated: false, owner: "cue.mod/module.cue", description: "CUE module metadata.", allowedExtensions: [".cue"], validatesWith: ["cue vet ./..."]},
	]

	assets: [
		for filename in [
			"README.md",
			"justfile",
		] {
			path:      filename
			kind:      "file"
			role:      "tooling"
			lifecycle: "source"
			authority: "authoritative"
			generated: false
			owner:     "github.com/fatb4f/contract.cuemod"
			validatesWith: ["cue vet ./contracts/assertions"]
		},
	]

	fixtures: [
		{path: "fixtures/mcp/valid", targetContract: "contracts/protocols/mcp", polarity: "valid", expected: "pass", validatesWith: "cue vet ./contracts/assertions"},
		{path: "fixtures/mcp/adapter-output", targetContract: "contracts/protocols/mcp", polarity: "valid", expected: "pass", validatesWith: "cue vet ./contracts/assertions"},
		{path: "fixtures/mcp/invalid-negative", targetContract: "contracts/protocols/mcp", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./contracts/assertions"},
		{path: "fixtures/mcp/invalid-direct", targetContract: "contracts/protocols/mcp", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./contracts/assertions"},
		{path: "fixtures/mcp/invalid-adapter-output", targetContract: "contracts/protocols/mcp", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./contracts/assertions"},
		{path: "fixtures/mcp/invalid-authority", targetContract: "contracts/protocols/mcp", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./contracts/assertions"},
		{path: "fixtures/mcp/invalid-capability", targetContract: "contracts/protocols/mcp", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./contracts/assertions"},
		{path: "fixtures/mcp/invalid-complete", targetContract: "contracts/protocols/mcp", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./contracts/assertions"},
		{path: "fixtures/mcp/invalid-provider-id", targetContract: "contracts/protocols/mcp", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./contracts/assertions"},
		{path: "fixtures/vcs/valid", targetContract: "contracts/vcs", polarity: "valid", expected: "pass", validatesWith: "cue vet ./contracts/assertions"},
		{path: "fixtures/vcs/invalid-unpushed", targetContract: "contracts/vcs", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./contracts/assertions"},
		{path: "fixtures/vcs/invalid-reflog-only", targetContract: "contracts/vcs", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./contracts/assertions"},
		{path: "fixtures/vcs/invalid-missing-transaction-policy", targetContract: "contracts/vcs", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./contracts/assertions"},
		{path: "fixtures/agent-skill/valid", targetContract: "contracts/agent-skill", polarity: "valid", expected: "pass", validatesWith: "cue vet ./contracts/assertions"},
		{path: "fixtures/agent-skill/invalid", targetContract: "contracts/agent-skill", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./contracts/assertions"},
		{path: "fixtures/resolver/workspace-lifecycle", targetContract: "contracts/context/packet", polarity: "valid", expected: "pass", validatesWith: "cue vet ./contracts/assertions"},
	]

	generatedAssets: [
		{path: ".repo/manifest.json", generated: true, source: "contracts/repo", projection: "projections/repo:manifest", command: "cue export ./projections/repo -e manifest", editable: false, validatesWith: ["cue vet ./contracts/assertions"]},
		{path: ".repo/inventory.json", generated: true, source: "contracts/repo", projection: "projections/repo:inventory", command: "cue export ./projections/repo -e inventory", editable: false, validatesWith: ["cue vet ./contracts/assertions"]},
		{path: ".repo/layout.md", generated: true, source: "contracts/repo", projection: "projections/repo:layoutMarkdown", command: "cue export ./projections/repo -e layoutMarkdown --out text", editable: false, validatesWith: ["cue vet ./contracts/assertions"]},
	]
}
