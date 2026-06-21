package contractsurfaceinput

#EvidenceKind: "pull_request" | "commit" | "release"

#SourceRef: {
	name: string
	kind: "branch" | "release_line" | "tag"
	required: bool | *true
}

source_scope: {
	upstream_repo: "openai/codex"

	refs: {
		main: {
			name: "main"
			kind: "branch"
		}
		alpha_latest: {
			name: "alpha-latest"
			kind: "release_line"
		}
	}

	evidence_kinds: [
		"pull_request",
		"commit",
		"release",
	]

	authority: {
		upstream: "evidence_only"
		local: "cue_contracts_agents_templates"
	}

	initial_gate: {
		acquisition_enabled: false
		reason: "Z0 to Z1 handoff scaffold only"
	}
}
