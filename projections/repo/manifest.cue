package repo

import repocontract "github.com/fatb4f/contract.cuemod/contracts/repo:repo"

manifest: repocontract.#RepoLayout & {
	module: "github.com/fatb4f/contract.cuemod"

	surfaces: [
		{path: "contracts/", kind: "directory", role: "authority", lifecycle: "source", authority: "authoritative", generated: false, owner: "contracts/repo", description: "Authoritative CUE contracts.", allowedExtensions: [".cue"], validatesWith: ["cue vet ./contracts/..."]},
		{path: "providers/", kind: "directory", role: "provider", lifecycle: "source", authority: "authoritative", generated: false, owner: "contracts/providers", description: "Concrete provider declarations.", allowedExtensions: [".cue"], validatesWith: ["cue vet ./providers/..."]},
		{path: "adapters/", kind: "directory", role: "adapter", lifecycle: "managed-snapshot", authority: "non-authority", generated: false, owner: "contracts/adapters", description: "Managed backend source snapshots.", forbiddenChildren: [".git"], validatesWith: ["cue vet ./adapters/git-mcp-go"]},
		{path: "projections/", kind: "directory", role: "projection", lifecycle: "source", authority: "derived", generated: false, owner: "contracts/repo", description: "Bounded views derived from contracts.", allowedExtensions: [".cue"], validatesWith: ["cue vet ./projections/..."]},
		{path: "fixtures/", kind: "directory", role: "fixture", lifecycle: "test-fixture", authority: "non-authority", generated: false, owner: "contracts/validation", description: "Canonical valid and invalid evidence.", validatesWith: ["./test/check.sh"]},
		{path: "migration/", kind: "directory", role: "migration", lifecycle: "quarantine", authority: "quarantined", generated: false, owner: "contracts/repo", description: "Quarantined observations awaiting classification.", validatesWith: ["cue vet ./migration"]},
		{path: "test/", kind: "directory", role: "validation", lifecycle: "source", authority: "non-authority", generated: false, owner: "contracts/validation", description: "Repository validation harness.", validatesWith: ["./test/check.sh"]},
		{path: "docs/", kind: "directory", role: "documentation", lifecycle: "source", authority: "non-authority", generated: false, owner: "contracts/repo", description: "Explanatory non-authority documentation.", allowedExtensions: [".md"], validatesWith: ["./test/check.sh"]},
		{path: ".codex/", kind: "directory", role: "generated", lifecycle: "generated", authority: "derived", generated: true, owner: "projections/agent-skill", description: "Generated agent runtime projection.", validatesWith: ["./test/agent-context-hook.sh"]},
		{path: ".repo/", kind: "directory", role: "generated", lifecycle: "generated", authority: "derived", generated: true, owner: "projections/repo", description: "Generated repository manifest and inventory.", validatesWith: ["./test/repo-layout.sh"]},
		{path: "contract/", kind: "directory", role: "authority", lifecycle: "deprecated", authority: "legacy", generated: false, owner: "contracts/repo", description: "Legacy authority packages pending migration.", replacement: "contracts/", validatesWith: ["cue vet ./contract/vcs"]},
		{path: "cmd/", kind: "directory", role: "tooling", lifecycle: "source", authority: "non-authority", generated: false, owner: "contracts/mcp", description: "Go command adapters.", validatesWith: ["go test ./..."]},
		{path: "internal/", kind: "directory", role: "tooling", lifecycle: "source", authority: "non-authority", generated: false, owner: "contracts/mcp", description: "Internal Go implementation packages.", validatesWith: ["go test ./..."]},
		{path: "bin/", kind: "directory", role: "tooling", lifecycle: "source", authority: "non-authority", generated: false, owner: "contracts/repo", description: "Developer-only tooling; never agent-visible.", validatesWith: ["./test/repo-layout.sh"], prunesWith: ["reject generated references to bin/"]},
		{path: "cue.mod/", kind: "directory", role: "tooling", lifecycle: "source", authority: "authoritative", generated: false, owner: "cue.mod/module.cue", description: "CUE module metadata.", allowedExtensions: [".cue"], validatesWith: ["cue vet ./..."]},
	]

	assets: [
		for filename in [
			"README.md",
			"agent.search.schema.cue",
			"dotfiles.agent-context.cue",
			"dotfiles.jsonld.cue",
			"dotfiles.schema-map.cue",
			"dotfiles.schema-map.json",
			"go.mod",
			"go.sum",
			"justfile",
			"mcp.runtime.cue",
			"workspace.contract.json",
			"workspace.cue",
			"workspace.domains.cue",
			"workspace.domains.json",
			"workspace.hosts.cue",
			"workspace.hosts.json",
			"workspace.projections.cue",
			"workspace.projects.cue",
			"workspace.projects.json",
			"workspace.schema.cue",
			"workspace.workflow.cue",
			"workspace.workflow.json",
			"workspace_tool.cue",
		] {
			path:      filename
			kind:      "file"
			role:      "tooling"
			lifecycle: "source"
			authority: "authoritative"
			generated: false
			owner:     "github.com/fatb4f/contract.cuemod"
			validatesWith: ["./test/check.sh"]
		},
	]

	fixtures: [
		{path: "fixtures/mcp/valid", targetContract: "contracts/mcp", polarity: "valid", expected: "pass", validatesWith: "cue vet ./fixtures/mcp/valid"},
		{path: "fixtures/mcp/adapter-output", targetContract: "contracts/mcp", polarity: "valid", expected: "pass", validatesWith: "cue vet ./fixtures/mcp/adapter-output"},
		{path: "fixtures/mcp/invalid-negative", targetContract: "contracts/mcp", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./fixtures/mcp/invalid-negative"},
		{path: "fixtures/mcp/invalid-direct", targetContract: "contracts/mcp", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./fixtures/mcp/invalid-direct"},
		{path: "fixtures/mcp/invalid-adapter-output", targetContract: "contracts/mcp", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./fixtures/mcp/invalid-adapter-output"},
		{path: "fixtures/mcp/invalid-authority", targetContract: "contracts/mcp", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./fixtures/mcp/invalid-authority"},
		{path: "fixtures/mcp/invalid-capability", targetContract: "contracts/mcp", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./fixtures/mcp/invalid-capability"},
		{path: "fixtures/mcp/invalid-complete", targetContract: "contracts/mcp", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./fixtures/mcp/invalid-complete"},
		{path: "fixtures/mcp/invalid-provider-id", targetContract: "contracts/mcp", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./fixtures/mcp/invalid-provider-id"},
		{path: "fixtures/vcs/valid", targetContract: "contract/vcs", polarity: "valid", expected: "pass", validatesWith: "cue vet ./fixtures/vcs/valid"},
		{path: "fixtures/vcs/invalid-unpushed", targetContract: "contract/vcs", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./fixtures/vcs/invalid-unpushed"},
		{path: "fixtures/vcs/invalid-reflog-only", targetContract: "contract/vcs", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./fixtures/vcs/invalid-reflog-only"},
		{path: "fixtures/vcs/invalid-missing-transaction-policy", targetContract: "contract/vcs", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./fixtures/vcs/invalid-missing-transaction-policy"},
		{path: "fixtures/agent-skill/valid", targetContract: "contracts/agent-skill", polarity: "valid", expected: "pass", validatesWith: "cue vet ./fixtures/agent-skill/valid"},
		{path: "fixtures/agent-skill/invalid", targetContract: "contracts/agent-skill", polarity: "invalid", expected: "fail", validatesWith: "cue vet ./fixtures/agent-skill/invalid"},
		{path: "fixtures/resolver/workspace-lifecycle", targetContract: "contracts/resolver", polarity: "valid", expected: "pass", validatesWith: "cue vet ./fixtures/resolver/workspace-lifecycle"},
	]

	generatedAssets: [
		{path: ".repo/manifest.json", generated: true, source: "contracts/repo", projection: "projections/repo:manifest", command: "cue export ./projections/repo -e manifest", editable: false, validatesWith: ["./test/repo-layout.sh"]},
		{path: ".repo/inventory.json", generated: true, source: "contracts/repo", projection: "projections/repo:inventory", command: "cue export ./projections/repo -e inventory", editable: false, validatesWith: ["./test/repo-layout.sh"]},
		{path: ".repo/layout.md", generated: true, source: "contracts/repo", projection: "projections/repo:layoutMarkdown", command: "cue export ./projections/repo -e layoutMarkdown --out text", editable: false, validatesWith: ["./test/repo-layout.sh"]},
	]
}
