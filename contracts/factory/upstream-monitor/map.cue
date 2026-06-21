package upstreammonitor

#ZoneID: "z0_instruction" |
	"z1_toolkit" |
	"z2_acquisition" |
	"z3_compute" |
	"z4_output"

#ToolkitRole: "acquisition" |
	"inference" |
	"formatting" |
	"output"

#SignalID: "loop_bootstrap_request" |
	"toolkit_ready" |
	"evidence_ready" |
	"impact_ready" |
	"artifacts_ready" |
	"terminal_success" |
	"terminal_abort" |
	"terminal_deferred" |
	"coverage_gap"

#ControlAction: "continue" |
	"hold" |
	"retry" |
	"degrade" |
	"abort" |
	"escalate"

#FailureState: "input_missing" |
	"input_invalid" |
	"transform_violation" |
	"output_invalid" |
	"eval_failed" |
	"mutation_blocked"

#MutationMode: "none" |
	"read_only" |
	"write_declared_output"

#Signal: {
	id: #SignalID
	producer: string
	consumer?: string
	payload?: _
}

#EvalGate: {
	pass: [...string]
	fail: [...string]
	error_signal?: #FailureState
}

#Transition: {
	from: #ZoneID
	to?: #ZoneID
	output: #Signal
	input?: #Signal
	action: #ControlAction

	terminal: bool | *false
	terminal_state?: #SignalID

	if terminal == false {
		to: #ZoneID
		input: #Signal & {
			id: output.id
		}
	}

	if terminal == true {
		terminal_state: "terminal_success" |
			"terminal_abort" |
			"terminal_deferred" |
			"coverage_gap"
	}
}

#Zone: {
	id: #ZoneID
	name: string
	input: [...#Signal]
	transform: string
	output: [...#Signal]
	eval: #EvalGate
	error_signal?: #FailureState
	control_action: #ControlAction
	next_state: [...#Transition]
}

#ComputeNode: {
	id: string
	zone: #ZoneID

	input: [...#Signal]
	transform: string
	output: [...#Signal]

	eval: #EvalGate

	next_state: [...#Transition]
}

#ToolkitNode: {
	id: string
	role: #ToolkitRole
	zone: #ZoneID

	input_signals: [...#SignalID]
	output_signals: [...#SignalID]

	mutation: #MutationMode | *"none"
	inference_allowed: bool | *false
	adapter?: string
	constraints: [...string]
}

#LoopToolkit: {
	id: string
	target: string

	roles: {
		acquisition: #ToolkitNode & {
			role: "acquisition"
			zone: "z2_acquisition"
			inference_allowed: false
			mutation: "read_only" | *"none"
		}
		inference: #ToolkitNode & {
			role: "inference"
			zone: "z3_compute"
			inference_allowed: true
			mutation: "none"
		}
		formatting: #ToolkitNode & {
			role: "formatting"
			zone: "z4_output"
			inference_allowed: false
			mutation: "none"
		}
		output: #ToolkitNode & {
			role: "output"
			zone: "z4_output"
			inference_allowed: false
			mutation: "write_declared_output"
		}
	}

	variable_surfaces?: [...#VariableSurface]
	invariants: [...string]
}

#VariableSurface: {
	id: string
	terms: [_, ...string]
	classes: [_, ...string]

	constraints: {
		require_any_term: bool | *true
		require_class: bool | *true
		require_local_contract_hint: bool | *true
		report_requires_local_impact: bool | *true
	}

	local_contract_hint?: string
}
