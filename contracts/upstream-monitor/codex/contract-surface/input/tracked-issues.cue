package contractsurfaceinput

#TrackedIssue: {
	repo: "fatb4f/contract.cuemod"
	number: int
	role: string
	impact_floor: "note" | "contract-update" | "blocking-gate"
}

tracked_issues: [
	{
		repo: "fatb4f/contract.cuemod"
		number: 42
		role: "local Codex contract-surface authority issue"
		impact_floor: "note"
	},
	{
		repo: "fatb4f/contract.cuemod"
		number: 47
		role: "resolver or context injection contract issue"
		impact_floor: "contract-update"
	},
	{
		repo: "fatb4f/contract.cuemod"
		number: 48
		role: "agent/plugin bundle or adapter contract issue"
		impact_floor: "contract-update"
	},
]
