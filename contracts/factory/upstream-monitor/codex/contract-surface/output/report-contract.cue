package contractsurfaceoutput

#Severity: "critical" | "high" | "note" | "none"

#ReportItem: {
	title: string
	severity: #Severity
	classification: [...string]
	impact_decision: "note" | "contract-update" | "blocking-gate" | "none"
	local_contract_impact?: string
	suggested_local_targets?: [...string]
	tracked_issue_refs?: [...int]
}

#ImpactReport: {
	resolved_commit_sha: string
	critical: [...#ReportItem]
	high: [...#ReportItem]
	notes: [...#ReportItem]
	no_local_action: [...#ReportItem]
}

report_output_contract: {
	path: "contracts/factory/upstream-monitor/codex/contract-surface/reports/latest.md"
	template: "contracts/factory/upstream-monitor/codex/contract-surface/output/report-template.md"
	enabled_initial_gate: false
}
