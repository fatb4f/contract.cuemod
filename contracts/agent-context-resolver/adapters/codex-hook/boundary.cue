package codexhookadapter

import adapters "github.com/fatb4f/contract.cuemod/contracts/adapters"

boundary: adapters.#AdapterBoundary & {
	id:   "agent-context-resolver.adapters.codex-hook"
	kind: "codex-hook"
}
