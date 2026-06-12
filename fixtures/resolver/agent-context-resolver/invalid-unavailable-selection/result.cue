package invalidunavailableselection

import "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver:agentcontextresolver"

exchange: agentcontextresolver.#UserPromptSubmitContract & {
	input: {
		prompt: "Select an unavailable fragment"
		availableFragmentIDs: ["agent-context-resolver.authority"]
	}
	output: {
		selectedFragments: ["mcp.evidence-plane"]
		compactHints: ["invalid selection"]
		evidence: [{
			kind:   "route_default"
			value:  "invalid"
			source: "user_prompt"
		}]
	}
}
