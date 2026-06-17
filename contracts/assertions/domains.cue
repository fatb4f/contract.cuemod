package assertions

import (
	"list"

	registry "github.com/fatb4f/contract.cuemod/contracts:registry"
)

_rootDomainIDs: [
	for contract in registry.repoRegistry.contracts {
		contract.id
	},
]

rootDomains: {
	authority: "cue"
	evaluator: ["cue eval", "cue vet"]

	required: [
		"agent-context-resolver",
		"agent-runtime",
		"agent-skill",
		"mcp",
		"resolver",
		"repo",
		"vcs",
		"vb-contract",
		"vb-reference",
	]

	for id in required {
		if !list.Contains(_rootDomainIDs, id) {
			_missingRootDomain: _|_
		}
	}
}
