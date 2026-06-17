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
	kind:   "prompt_term" | "prompt_route" | "route_default"
	value:  string
	source: "user_prompt"
}

#ExpectedEvidence: {
	kind:        "prompt_evidence" | "route_worker_evidence"
	required:    true
	description: string & !=""
}

#UserPromptSubmitOutput: {
	schema: "agent.route-controller-packet.v1"
	selectedFragments: [...string]
	compactHints: [...string]
	evidence: [...#Evidence]
	expectedEvidence?: [...#ExpectedEvidence]
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
