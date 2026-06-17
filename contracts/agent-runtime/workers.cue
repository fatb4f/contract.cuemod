package agentruntime

#RuntimeID: string & =~"^[a-z0-9][a-z0-9._-]*$"

#RouteKind:
	"inspect" |
	"validate" |
	"generate" |
	"diff" |
	"test" |
	"summarize" |
	"risk_scan"

#WorkerCapability:
	"inspect" |
	"validate" |
	"generate_patch_plan" |
	"run_declared_commands" |
	"collect_evidence" |
	"summarize"

#DeniedInputs: close({
	arbitraryPrompt:         true
	rawTranscript:           true
	rawRegistry:             true
	unselectedFragments:     true
	unboundedToolLogs:       true
	globalMutationAuthority: true
})

#WorkerProfile: close({
	id:    #RuntimeID
	label: string & !=""
	capabilities: [...#WorkerCapability] & [_, ...]
	allowedRouteKinds: [...#RouteKind] & [_, ...]
	executorAdapterID: #RuntimeID
	backendAdapterID:  #RuntimeID
	budgetID:          #RuntimeID
	deniedInputs:      #DeniedInputs
})

workerProfiles: [...#WorkerProfile] & [
	{
		id:    "codex-route-inspector"
		label: "Bounded read and evidence worker"
		capabilities: ["inspect", "collect_evidence", "summarize"]
		allowedRouteKinds: ["inspect", "summarize", "risk_scan"]
		executorAdapterID: "mcp-route-executor"
		backendAdapterID:  "codex-sdk-hidden"
		budgetID:          "inspect-standard"
		deniedInputs: {
			arbitraryPrompt:         true
			rawTranscript:           true
			rawRegistry:             true
			unselectedFragments:     true
			unboundedToolLogs:       true
			globalMutationAuthority: true
		}
	},
	{
		id:    "codex-route-validator"
		label: "Bounded validation and patch planning worker"
		capabilities: ["inspect", "validate", "generate_patch_plan", "run_declared_commands", "collect_evidence", "summarize"]
		allowedRouteKinds: ["validate", "generate", "diff", "test"]
		executorAdapterID: "mcp-route-executor"
		backendAdapterID:  "codex-sdk-hidden"
		budgetID:          "validate-standard"
		deniedInputs: {
			arbitraryPrompt:         true
			rawTranscript:           true
			rawRegistry:             true
			unselectedFragments:     true
			unboundedToolLogs:       true
			globalMutationAuthority: true
		}
	},
]
