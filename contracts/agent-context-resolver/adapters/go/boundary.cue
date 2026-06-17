package goadapter

import adapters "github.com/fatb4f/contract.cuemod/contracts/adapters"

boundary: adapters.#AdapterBoundary & {
	id:   "agent-context-resolver.adapters.go"
	kind: "go-wrapper"
}
