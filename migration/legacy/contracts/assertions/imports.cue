package assertions

import (
	"list"
	"strings"

	registry "github.com/fatb4f/contract.cuemod/contracts:registry"
)

rootRegistryImports: {
	for contract in registry.repoRegistry.contracts {
		if strings.Contains(contract.authorityRoot, "/projections/") ||
			strings.Contains(contract.authorityRoot, "/adapters/") {
			_componentLocalBindingRegisteredAsRootAuthority: _|_
		}

		for fragment in contract.fragments {
			if strings.Contains(fragment.sourcePath, "/projections/") ||
				strings.Contains(fragment.sourcePath, "/adapters/") {
				_componentLocalFragmentRegisteredAsRootAuthority: _|_
			}
		}
	}

	rootAuthorityIDs: [
		for contract in registry.repoRegistry.contracts {
			if list.Contains([for fragment in contract.fragments {fragment.role}], "authority") {
				contract.id
			}
		},
	]
}
