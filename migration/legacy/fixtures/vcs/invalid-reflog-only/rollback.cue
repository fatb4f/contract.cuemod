package invalidreflogonly

import "github.com/fatb4f/contract.cuemod/contracts/vcs"

rollback: vcs.#RollbackPolicy & {
	class: "index_only"
	surfaces: ["index"]
	requiredSnapshots: ["index"]
	allowed: ["consult_reflog"]
	forbidden: ["git reset --hard"]
	reflogSufficient: true
}
