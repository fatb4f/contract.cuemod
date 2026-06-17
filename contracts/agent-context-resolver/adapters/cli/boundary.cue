package cliadapter

import adapters "github.com/fatb4f/contract.cuemod/contracts/adapters"

boundary: adapters.#AdapterBoundary & {
	id:   "agent-context-resolver.adapters.cli"
	kind: "cli"
}
