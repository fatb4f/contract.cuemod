package contractsurfaceoutput

#IssueUpdate: {
	target_repo: "fatb4f/contract.cuemod"
	target_issue: 42 | 47 | 48
	impact_decision: "note" | "contract-update" | "blocking-gate"
	upstream_evidence_summary: string
	local_contract_impact: string
	suggested_local_targets: [...string]
}

issue_update_contract: {
	template: "contracts/factory/upstream-monitor/codex/contract-surface/output/issue-update-template.md"
	enabled_initial_gate: false
	allowed_targets: [
		{
			repo: "fatb4f/contract.cuemod"
			issue: 42
		},
		{
			repo: "fatb4f/contract.cuemod"
			issue: 47
		},
		{
			repo: "fatb4f/contract.cuemod"
			issue: 48
		},
	]
}
