package seedresolver

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
	selectedFragments: [...string]
	compactHints: [...string]
	evidence: [...#Evidence]

	fullRegistry?:  _|_
	contextBodies?: _|_
}

#UserPromptSubmitContract: {
	input:  #UserPromptSubmitInput
	output: #UserPromptSubmitOutput

	for _, id in output.selectedFragments {
		list.Contains(input.availableFragmentIDs, id)
	}
}
