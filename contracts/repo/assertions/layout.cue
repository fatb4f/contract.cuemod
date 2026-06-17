package assertions

import (
	"list"
	"strings"

	repoprojection "github.com/fatb4f/contract.cuemod/projections/repo:repo"
)

repoLayoutAssertions: {
	module: "github.com/fatb4f/contract.cuemod"

	authorityRoots: {
		required: ["contracts/"]
		forbidden: ["contract", "contract/"]
		singularAuthorityRootMustNotExist: true
	}

	projections: {
		manifest:       repoprojection.manifest
		inventory:      repoprojection.inventory
		layoutMarkdown: repoprojection.layoutMarkdown
		generated:      repoprojection.generated
	}

	topLevelInventory: {
		declared: [for item in repoprojection.inventory {strings.TrimSuffix(item.path, "/")}]
		expected: [
			".github",
			".repo",
			"README.md",
			"adapters",
			"contracts",
			"cue.mod",
			"docs",
			"fixtures",
			"justfile",
			"projections",
			"providers",
			"test",
		]
		for path in expected {
			if !list.Contains(declared, path) {
				_missingDeclaredTopLevelPath: _|_
			}
		}
		for path in declared {
			if !list.Contains(expected, path) {
				_undeclaredTopLevelPath: _|_
			}
		}
	}

	policy: {
		onlyPluralContractAuthority:                    true
		noManagedAdapterGitMetadata:                    true
		noRepoLevelBinReferencesInGeneratedAgentAssets: true
		noSingularAuthorityRootReferences:              true
	}

	generatedAssets: [
		{path: ".repo/manifest.json", projection: "projections/repo:manifest", command: "cue export ./projections/repo -e manifest"},
		{path: ".repo/inventory.json", projection: "projections/repo:inventory", command: "cue export ./projections/repo -e inventory"},
		{path: ".repo/layout.md", projection: "projections/repo:layoutMarkdown", command: "cue export ./projections/repo -e layoutMarkdown --out text"},
	]

	for asset in generatedAssets {
		if !list.Contains([for declared in repoprojection.manifest.generatedAssets {declared.path}], asset.path) {
			_missingGeneratedAssetDeclaration: _|_
		}
	}
}
