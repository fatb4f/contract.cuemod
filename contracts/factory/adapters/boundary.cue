package adapters

import workers "github.com/fatb4f/contract.reflective-transition-factory/contracts/factory/workers"

#WorkerApertureAdapter: close({
	id:      string & !=""
	worker: workers.#WorkerAperture
	role:    "worker-aperture-adapter"
})

boundary: close({
	allowedRoles: ["worker-aperture-adapter"]
	forbiddenAuthorityRoots: [
		"raw-repo",
		"raw-vcs",
		"plugin-bundle-generated-artifact",
	]
})
