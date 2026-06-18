package assertions

import registry "github.com/fatb4f/contract.cuemod/contracts:registry"

resolverLocalProjectionAssertions: {
	rootRegistry: registry.repoRegistry

	componentLocalPaths: [
		"contracts/agent-context-resolver/projections",
		"contracts/agent-context-resolver/adapters",
	]

	for contract in rootRegistry.contracts {
		for path in componentLocalPaths {
			if contract.authorityRoot == path {
				_componentLocalPathRegisteredAsRootAuthority: _|_
			}
			for fragment in contract.fragments {
				if fragment.sourcePath == path {
					_componentLocalFragmentRegisteredAsRootAuthority: _|_
				}
			}
		}
	}

	authority:   false
	extractable: false
}
