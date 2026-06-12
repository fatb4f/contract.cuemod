package seedresolver

#ProofCheck: {
	id:   string
	pass: true
}

#LifecycleReport: {
	version: "contract-cuemod.agent-context-resolver-proof/v1"
	checks: [...#ProofCheck] & [_, ...]
}
