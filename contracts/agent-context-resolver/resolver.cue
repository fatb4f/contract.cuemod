package agentcontextresolver

import "list"

#DeclaredID: string & =~"^[a-z0-9][a-z0-9._-]*$"

#ContextFragment: close({
	id:    #DeclaredID
	surface: "turn_start" | "prompt" | "mcp"
	channel: "message" | "item" | "resource"
	itemKind: "message" | "resource" | "tool_output"
	expectedNativeContextInjection: bool
	label: string & !=""

	if surface == "turn_start" {
		channel: "message"
		itemKind: "message"
		expectedNativeContextInjection: true
	}
})

#Registry: close({
	fragments: [...#ContextFragment]
})

#TurnStartContextFragmentSet: close({
	fragments: [...#ContextFragment & {surface: "turn_start"}]
})

#PromptHint: close({
	domain?: string
	workflow?: string
	authorityRoot?: string
	risk?: string
})

#PromptEvidence: close({
	matchedRules: [...string & !=""]
	rejectedRules?: [...string & !=""]
})

#PromptClassification: close({
	selectedFragments: [...#DeclaredID]
	hints: #PromptHint
	evidence: #PromptEvidence
})

#LifecycleAssertion: close({
	name: string & !=""
	passed: bool
	detail?: string & !=""
})

#ResolverLifecycleReport: close({
	schema: "agent.context-resolver.lifecycle-report.v1"
	turnStart: #TurnStartContextFragmentSet
	classification: #PromptClassification
	assertions: [#LifecycleAssertion, ...#LifecycleAssertion]
	for _, id in classification.selectedFragments {
		list.Contains([for fragment in turnStart.fragments {fragment.id}], id)
	}
})

#ResolverOutput: close({
	schema:   "agent.context-resolver.output.v1"
	prompt:   string & !=""
	report:   #ResolverLifecycleReport
	hook: {
		hook_event_name: "UserPromptSubmit"
		additionalContext: string & !=""
	}
})

#RegistryMatch: {
	registry: #Registry
	classification: #PromptClassification

	allowedFragmentIDs: [for entry in registry.fragments {entry.id}]

	for _, id in classification.selectedFragments {
		list.Contains(allowedFragmentIDs, id)
	}
}
