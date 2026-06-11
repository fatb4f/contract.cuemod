package adapters

#ManagedAdapter: close({
	id: string & =~"^df:adapter/[a-z0-9._-]+$"

	kind:      "source-snapshot"
	authority: "privileged-backend"
	exposure:  "internal-only"

	source: close({
		repository: string & =~"^https://github\\.com/"
		forkOf?:    string & =~"^https://github\\.com/"
		branch:     string & !=""
		revision:   string & =~"^[0-9a-f]{40}$"
		archive:    string & =~"^https://github\\.com/"
	})

	materialization: close({
		path:             string & !=""
		nestedGit:        false
		updateStrategy:   "replace-source-snapshot"
		preserveUpstream: true
		allowedChanges: [...string]
		forbiddenMetadata: [...string & !=""] & [_, ...]
	})

	contractBoundary: string & !=""
	validatesWith: [...string & !=""] & [_, ...]

	runtime: close({
		language:   "go"
		module:     string & !=""
		executable: string & !=""
		modes: [...string & !=""] & [_, ...]
	})

	capabilities: [...string & !=""] & [_, ...]
})
