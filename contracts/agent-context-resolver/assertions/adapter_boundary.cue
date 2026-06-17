package assertions

import (
	rootadapters "github.com/fatb4f/contract.cuemod/contracts/adapters"
	resolveradapters "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver/adapters:adapters"
)

adapterBoundaryAssertions: {
	rootVocabulary: rootadapters.adapterVocabularyBoundary & {
		authority:   true
		extractable: true
	}

	resolverAdapters: resolveradapters.section & {
		id:   "agent-context-resolver.adapters"
		kind: "adapters"
		path: "adapters"
	}

	invariants: {
		cueOwnsValidation: true
		adapterOwnsIO:     true
		duplicateLogic:    false
		semanticAuthority: false
	}
}
