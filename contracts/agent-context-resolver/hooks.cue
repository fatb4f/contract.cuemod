package agentcontextresolver

import "list"

#TurnStartInput: {
	registryIndex: "registry.index.json"
}

#TurnStartOutput: #TurnStartFragmentSet

#UserPromptSubmitInput: {
	prompt: string
	availableFragmentIDs: [...string]
}

#Evidence: {
	kind:   "prompt_term" | "route_default"
	value:  string
	source: "user_prompt"
}

#UserPromptSubmitOutput: {
	schema: "agent.route-controller-packet.v1"
	selectedFragments: [...string]
	compactHints: [...string]
	evidence: [...#Evidence]
	controller: #ResolvedRoutePlan

	fullRegistry?:   _|_
	contextBodies?:  _|_
	fullTranscript?: _|_
}

#UserPromptSubmitContract: {
	input:  #UserPromptSubmitInput
	output: #UserPromptSubmitOutput

	for _, id in output.selectedFragments {
		list.Contains(input.availableFragmentIDs, id)
	}
}
