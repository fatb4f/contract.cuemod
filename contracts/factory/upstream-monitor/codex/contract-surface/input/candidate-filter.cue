package contractsurfaceinput

#EventKind: "pull_request" | "commit" | "release"

#ImpactDecision: "none" |
	"note" |
	"contract-update" |
	"blocking-gate"

#CandidateEvent: {
	id: string
	kind: #EventKind
	repo: "openai/codex"
	ref: "main" | "alpha-latest"
	title?: string
	path_hints?: [...string]
	text_hints?: [...string]
	matched_terms: [...string]
	classes: [...#SurfaceClass]
	surface_matches?: [...#SurfaceMatch]
}

#SurfaceMatch: {
	surface_id: string
	matched_terms: [_, ...string]
	classes: [_, ...#SurfaceClass]
	constraints: #SurfaceConstraint
	local_contract_hint: string
}

#ImpactCandidate: #CandidateEvent & {
	matched_terms: [_, ...string]
	classes: [_, ...#SurfaceClass]
	surface_matches: [_, ...#SurfaceMatch]
	authority: "upstream_evidence_only"
	local_authority: "fatb4f_contracts_cue"
	decision: #ImpactDecision
	report: bool
	local_contract_impact: string
	suggested_local_targets?: [...string]
	tracked_issue_refs?: [...int]
}

#FilterGate: {
	name: string
	input: string
	constraint: string
	failure: string
}

candidate_filter: {
	phase: "spec_only"
	acquisition_enabled: false

	source: source_scope
	surface_catalogue: surface_catalogue
	tracked_issues: tracked_issues

	toolkit_role: {
		owner: "inference"
		input_signal: "evidence_ready"
		output_signal: "impact_ready"
		mutation: "none"
	}

	include: {
		repo: "openai/codex"
		refs: ["main", "alpha-latest"]
		kinds: ["pull_request", "commit", "release"]
	}

	variable_surface_policy: {
		defined_by: "surface_catalogue"
		admitted_by: [
			"terms",
			"classes",
			"constraints",
			"local_contract_hint",
		]
		reject_if: [
			"no surface term match",
			"no class match",
			"no local contract impact",
			"event kind outside surface constraints",
		]
		forbid: [
			"hard-coded event path admission outside CUE",
			"semantic classification in acquisition scripts",
			"upstream evidence promoted to authority",
		]
	}

	gates: [
		{
			name: "source_scope"
			input: "candidate event"
			constraint: "repo, ref, and kind must match source_scope"
			failure: "coverage_gap"
		},
		{
			name: "surface_match"
			input: "candidate event"
			constraint: "candidate must match at least one declared variable surface"
			failure: "coverage_gap"
		},
		{
			name: "local_impact"
			input: "surface match"
			constraint: "reported candidates must declare local contract impact"
			failure: "terminal_deferred"
		},
		{
			name: "decision_admission"
			input: "impact candidate"
			constraint: "decision must reduce to none, note, contract-update, or blocking-gate"
			failure: "eval_failed"
		},
	]

	match_policy: {
		require_surface_term: true
		require_surface_constraint: true
		require_local_contract_impact_for_report: true
		treat_upstream_as: "evidence_not_authority"
		report_only: ["note", "contract-update", "blocking-gate"]
	}

	classification: {
		allowed: [
			"protocol",
			"adapter",
			"storage",
			"policy",
			"UI",
			"docs",
			"context-window",
			"multi-agent",
			"rollout-trace",
			"mcp",
			"config",
			"security",
		]
	}

	decision_lattice: {
		none: {
			report: false
			meaning: "matched event has no admitted local contract impact"
		}
		note: {
			report: true
			meaning: "local contract awareness only"
		}
		"contract-update": {
			report: true
			meaning: "local CUE contract or surface catalogue may need revision"
		}
		"blocking-gate": {
			report: true
			meaning: "local assumptions may be invalid until a gate is reviewed"
		}
	}

	report_shape: {
		sections: [
			"Critical",
			"High",
			"Notes",
			"No local action",
		]
		required_fields: [
			"event",
			"surface_matches",
			"classification",
			"impact_decision",
			"local_contract_impact",
			"suggested_local_targets",
			"tracked_issue_refs",
		]
	}

	forbidden_initial_gate: [
		"execute search",
		"fetch openai/codex",
		"render report",
		"post issue update",
	]
}
