package invalidmissingtransactionpolicy

import "github.com/fatb4f/contract.cuemod/contracts/vcs"

operation: vcs.#SkillOperation & {
	id:          "stack.stage"
	class:       "local-mutation"
	agentFacing: true
	requires: {
		activePatch: true
		transaction: true
	}
	effects: {
		writes: ["index"]
		changesIndex: true
	}
	backendCapabilities: ["vcs.writeIndex"]
	rationale: "This fixture must fail because a stack mutator has no transaction policy."
}
