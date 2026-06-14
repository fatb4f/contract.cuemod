package agentcontextresolver

#GateClass:
	"registry_authority" |
	"propagation_boundary" |
	"runtime_denial" |
	"structured_result"

#Gate: close({
	id:    #DeclaredID
	class: #GateClass
	stage: "selection" | "projection" | "execution" | "merge"
	appliesToKinds: [...#RouteKind] & [_, ...]
	required: true
})

gateInventory: [...#Gate] & [
	{
		id:    "registry-authority"
		class: "registry_authority"
		stage: "selection"
		appliesToKinds: ["inspect", "validate", "generate", "diff", "test", "summarize", "risk_scan"]
		required: true
	},
	{
		id:    "route-local-propagation"
		class: "propagation_boundary"
		stage: "projection"
		appliesToKinds: ["inspect", "validate", "generate", "diff", "test", "summarize", "risk_scan"]
		required: true
	},
	{
		id:    "runtime-deny"
		class: "runtime_denial"
		stage: "execution"
		appliesToKinds: ["validate", "generate", "diff", "test", "risk_scan"]
		required: true
	},
	{
		id:    "structured-result"
		class: "structured_result"
		stage: "merge"
		appliesToKinds: ["inspect", "validate", "generate", "diff", "test", "summarize", "risk_scan"]
		required: true
	},
]
