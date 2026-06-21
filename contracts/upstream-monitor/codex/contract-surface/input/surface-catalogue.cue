package contractsurfaceinput

#SurfaceClass: "protocol" |
	"adapter" |
	"storage" |
	"policy" |
	"UI" |
	"docs" |
	"context-window" |
	"multi-agent" |
	"rollout-trace" |
	"mcp" |
	"config" |
	"security"

#SurfaceConstraint: {
	require_any_term: bool | *true
	require_class: bool | *true
	require_local_contract_hint: bool | *true
	report_requires_local_impact: bool | *true
	admissible_event_kinds: [...#EvidenceKind]
	impact_floor: #ImpactDecision | *"note"
}

#Surface: {
	id: string
	terms: [_, ...string]
	classes: [_, ...#SurfaceClass]
	constraints: #SurfaceConstraint
	local_contract_hint: string
}

surface_catalogue: [
	{
		id: "response_item"
		terms: ["ResponseItem", "ResponseItemMetadata"]
		classes: ["protocol"]
		constraints: {
			admissible_event_kinds: ["pull_request", "commit", "release"]
			impact_floor: "contract-update"
		}
		local_contract_hint: "response item schema and metadata contracts"
	},
	{
		id: "agent_messages"
		terms: ["AgentMessage", "InterAgentCommunication", "NEW_TASK", "MESSAGE", "FINAL_ANSWER"]
		classes: ["protocol", "multi-agent"]
		constraints: {
			admissible_event_kinds: ["pull_request", "commit", "release"]
			impact_floor: "contract-update"
		}
		local_contract_hint: "agent message envelope and lifecycle contracts"
	},
	{
		id: "agent_path"
		terms: ["AgentPath"]
		classes: ["adapter", "protocol"]
		constraints: {
			admissible_event_kinds: ["pull_request", "commit"]
			impact_floor: "note"
		}
		local_contract_hint: "agent path routing and adapter identity contracts"
	},
	{
		id: "context_fragments"
		terms: ["session_prefix", "context fragments", "fragment", "fragments"]
		classes: ["context-window", "adapter"]
		constraints: {
			admissible_event_kinds: ["pull_request", "commit", "release"]
			impact_floor: "contract-update"
		}
		local_contract_hint: "context injection and prompt fragment contracts"
	},
	{
		id: "rollout_trace"
		terms: ["rollout_trace", "rollout trace"]
		classes: ["rollout-trace", "storage"]
		constraints: {
			admissible_event_kinds: ["pull_request", "commit", "release"]
			impact_floor: "note"
		}
		local_contract_hint: "rollout trace evidence and replay contracts"
	},
	{
		id: "thread_store"
		terms: ["thread_store", "thread store", "rollout storage", "rollout_store"]
		classes: ["storage", "rollout-trace"]
		constraints: {
			admissible_event_kinds: ["pull_request", "commit", "release"]
			impact_floor: "contract-update"
		}
		local_contract_hint: "thread and rollout storage contracts"
	},
	{
		id: "mcp_handlers"
		terms: ["MCP", "resource handler", "tool handler", "resources/list", "tools/call"]
		classes: ["mcp", "adapter"]
		constraints: {
			admissible_event_kinds: ["pull_request", "commit", "release"]
			impact_floor: "contract-update"
		}
		local_contract_hint: "MCP resource/tool handler contracts"
	},
	{
		id: "agents_instructions"
		terms: ["AGENTS.md", "developer instructions", "developer_instruction", "instructions"]
		classes: ["policy", "docs"]
		constraints: {
			admissible_event_kinds: ["pull_request", "commit", "release"]
			impact_floor: "blocking-gate"
		}
		local_contract_hint: "AGENTS and policy instruction chain contracts"
	},
	{
		id: "config_feature_flags"
		terms: ["feature flag", "feature_flags", "config", "experimental"]
		classes: ["config"]
		constraints: {
			admissible_event_kinds: ["pull_request", "commit", "release"]
			impact_floor: "note"
		}
		local_contract_hint: "configuration and rollout-gate contracts"
	},
	{
		id: "security_boundary"
		terms: ["sandbox", "approval", "permissions", "auth", "token", "secret"]
		classes: ["security", "policy"]
		constraints: {
			admissible_event_kinds: ["pull_request", "commit", "release"]
			impact_floor: "blocking-gate"
		}
		local_contract_hint: "security boundary and approval contracts"
	},
]
