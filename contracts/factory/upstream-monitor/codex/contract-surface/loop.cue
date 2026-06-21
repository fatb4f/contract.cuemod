package contractsurface

import monitor "github.com/fatb4f/contract.reflective-transition-factory/contracts/factory/upstream-monitor"

z0_instruction: monitor.#ComputeNode & {
	id: "z0_instruction_bootstrap"
	zone: "z0_instruction"

	input: [{
		id: "loop_bootstrap_request"
		producer: "scheduled_chatgpt_task"
	}]

	transform: "resolve loop entrypoint through GitHub App adapter"

	output: [{
		id: "loop_bootstrap_request"
		producer: "z0_instruction"
		consumer: "z1_toolkit"
		payload: {
			repo: "fatb4f/contract.cuemod"
			ref: "factory/reflective-transition-factory"
			entrypoint: "contracts/factory/upstream-monitor/codex/contract-surface/AGENTS.md"
			adapter: "github_app"
		}
	}]

	eval: {
		pass: [
			"repo is explicit",
			"ref policy is explicit",
			"entrypoint AGENTS.md is explicit",
			"adapter is explicit",
		]
		fail: [
			"entrypoint inferred",
			"project files used before GitHub App",
			"non-Codex loop selected",
		]
		error_signal: "input_invalid"
	}

	next_state: [{
		from: "z0_instruction"
		to: "z1_toolkit"
		output: output[0]
		input: {
			id: "loop_bootstrap_request"
			producer: "z0_instruction"
			consumer: "z1_toolkit"
		}
		action: "continue"
	}]
}

z1_toolkit: monitor.#ComputeNode & {
	id: "z1_toolkit_entrypoint_acceptance"
	zone: "z1_toolkit"

	input: [z0_instruction.output[0]]

	transform: "load explicit AGENTS chain and loop-local toolkit contracts without acquiring upstream evidence"

	output: [{
		id: "toolkit_ready"
		producer: "z1_toolkit"
		consumer: "z2_acquisition"
		payload: {
			instruction_chain: [
				"contracts/factory/upstream-monitor/AGENTS.md",
				"contracts/factory/upstream-monitor/codex/AGENTS.md",
				"contracts/factory/upstream-monitor/codex/contract-surface/AGENTS.md",
			]
			toolkit: codex_contract_surface_toolkit.id
			initial_gate: "signal_continuity"
			acquisition_enabled: false
			reporting_enabled: false
			issue_posting_enabled: false
		}
	}]

	eval: {
		pass: [
			"Z1 input signal matches Z0 output signal",
			"instruction chain is explicit",
			"toolkit roles are explicit",
			"acquisition remains disabled",
			"reports and issue posting remain disabled",
		]
		fail: [
			"signal ID changed during handoff",
			"AGENTS chain inferred from layout",
			"toolkit role inferred from directory name",
			"upstream acquisition started during initial gate",
			"output mutation attempted during initial gate",
		]
		error_signal: "eval_failed"
	}

	next_state: [
		{
			from: "z1_toolkit"
			to: "z2_acquisition"
			output: output[0]
			input: {
				id: "toolkit_ready"
				producer: "z1_toolkit"
				consumer: "z2_acquisition"
			}
			action: "hold"
		},
		{
			from: "z1_toolkit"
			output: {
				id: "terminal_abort"
				producer: "z1_toolkit"
				payload: {
					reason: "input_invalid_or_adapter_failure"
				}
			}
			action: "abort"
			terminal: true
			terminal_state: "terminal_abort"
		},
	]
}

codex_contract_surface_toolkit: monitor.#LoopToolkit & {
	id: "codex_contract_surface_toolkit"
	target: "openai/codex"

	roles: {
		acquisition: {
			id: "codex_evidence_acquisition"
			input_signals: ["toolkit_ready"]
			output_signals: ["evidence_ready"]
			adapter: "github_app"
			mutation: "none"
			constraints: [
				"disabled during initial Z0 to Z1 gate",
				"when admitted, reads only declared refs and evidence kinds",
				"does not classify semantic impact",
			]
		}

		inference: {
			id: "codex_contract_surface_inference"
			input_signals: ["evidence_ready"]
			output_signals: ["impact_ready"]
			constraints: [
				"only role allowed to classify semantic impact",
				"candidate admission is constrained by CUE surface filters",
				"upstream evidence cannot mutate local authority",
			]
		}

		formatting: {
			id: "codex_impact_formatting"
			input_signals: ["impact_ready"]
			output_signals: ["artifacts_ready"]
			constraints: [
				"renders only admitted impact decisions",
				"uses loop-local report and issue templates",
				"does not fetch or infer new evidence",
			]
		}

		output: {
			id: "codex_ledger_output"
			input_signals: ["artifacts_ready"]
			output_signals: ["terminal_success"]
			constraints: [
				"writes only declared output paths after the output gate opens",
				"issue posting requires explicit admission by issue contract",
				"no output mutation during the initial gate",
			]
		}
	}

	invariants: [
		"loop is a contained toolkit",
		"roles are declared, not inferred from layout",
		"variable surfaces are CUE-constrained inputs",
		"acquisition, inference, formatting, and output remain distinct roles",
	]
}

transition_closure: {
	expected_path: [
		"z0_instruction",
		"z1_toolkit",
		"z2_acquisition",
		"z3_compute",
		"z4_output",
		"terminal_success",
	]

	failure_terminals: [
		"terminal_abort",
		"terminal_deferred",
		"coverage_gap",
	]

	initial_gate: {
		proof: "Z0.output.signal_id == Z1.input.signal_id"
		z0_output_signal: z0_instruction.output[0].id
		z1_input_signal: z1_toolkit.input[0].id
	}
}
