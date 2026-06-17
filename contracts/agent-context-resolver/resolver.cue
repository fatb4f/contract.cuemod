package agentcontextresolver

import "list"

#DeclaredID: string & =~"^[a-z0-9][a-z0-9._-]*$"

#ContextFragment: close({
	id:                             #DeclaredID
	surface:                        "turn_start" | "prompt" | "mcp"
	channel:                        "message" | "item" | "resource"
	itemKind:                       "message" | "resource" | "tool_output"
	expectedNativeContextInjection: bool
	label:                          string & !=""

	if surface == "turn_start" {
		channel:                        "message"
		itemKind:                       "message"
		expectedNativeContextInjection: true
	}
	if surface != "turn_start" {
		expectedNativeContextInjection: false
	}
	if itemKind == "tool_output" {
		expectedNativeContextInjection: false
	}
})

#Registry: close({
	fragments: [...#ContextFragment]
})

#TurnStartContextFragmentSet: close({
	fragments: [...#ContextFragment & {surface: "turn_start"}]
})

#PromptHint: close({
	domain?:        string
	workflow?:      string
	authorityRoot?: string
	risk?:          string
})

#PromptEvidence: close({
	matchedRules: [...string & !=""]
	rejectedRules?: [...string & !=""]
})

#PromptClassification: close({
	selectedFragments: [...#DeclaredID]
	hints:    #PromptHint
	evidence: #PromptEvidence
})

#LifecycleAssertionName:
	"turn_start_available" |
	"known_fragment_selected" |
	"context_body_not_assembled" |
	"mcp_tool_output_not_implied_context" |
	"controller_packet_not_sdk_subagent"

#LifecycleAssertion: close({
	name:    #LifecycleAssertionName
	passed:  true
	detail?: string & !=""
})

#ResolverLifecycleReport: close({
	schema:         "agent.context-resolver.lifecycle-report.v1"
	registry:       #Registry
	turnStart:      #TurnStartContextFragmentSet
	classification: #PromptClassification
	assertions: [#LifecycleAssertion, ...#LifecycleAssertion]
	for _, id in classification.selectedFragments {
		list.Contains([for fragment in registry.fragments {fragment.id}], id)
		list.Contains([for fragment in turnStart.fragments {fragment.id}], id)
	}
})

#ResolverOutput: close({
	schema: "agent.context-resolver.output.v1"
	prompt: string & !=""
	report: #ResolverLifecycleReport
	hook: close({
		hook_event_name: "UserPromptSubmit"
		selectedFragments: [...#DeclaredID]
		hints:             #PromptHint
		evidence:          #PromptEvidence
		additionalContext: string & !=""
		// Optional resolver-produced controller packet for route planning.
		// Execution adapters may consume it later, but this output does not
		// represent an SDK subagent.
		controller?: #ResolvedRoutePlan
	})
})

#RegistryMatch: {
	registry:       #Registry
	classification: #PromptClassification

	allowedFragmentIDs: [for entry in registry.fragments {entry.id}]

	for _, id in classification.selectedFragments {
		list.Contains(allowedFragmentIDs, id)
	}
}
