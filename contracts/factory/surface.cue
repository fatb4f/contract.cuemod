package factory

#SurfaceDisposition:
	"keep" |
	"quarantine" |
	"migrate" |
	"delete"

#PruningSurfaceEntry: close({
	path:        string & !=""
	disposition: #SurfaceDisposition
	reason:      string & !=""
})

#PruningSurface: close({
	keep: [...#PruningSurfaceEntry]
	quarantine: [...#PruningSurfaceEntry]
	delete: [...#PruningSurfaceEntry]
})

surface: #PruningSurface & {
	keep: [
		{
			path:        "contracts/factory"
			disposition: "keep"
			reason:      "new reflective transition factory authority surface"
		},
		{
			path:        "contracts/agent-runtime"
			disposition: "keep"
			reason:      "runtime event and packet migration source"
		},
		{
			path:        "contracts/agent-context-resolver"
			disposition: "keep"
			reason:      "first reflective selector and migration source"
		},
	]
	quarantine: [
		{
			path:        "contracts/agent-context-resolver/registry.cue"
			disposition: "quarantine"
			reason:      "legacy resolver registry glue may inform migration but is not factory authority"
		},
		{
			path:        "contracts/agent-context-resolver/projections"
			disposition: "quarantine"
			reason:      "old projection glue remains migration-only"
		},
		{
			path:        "contracts/graph"
			disposition: "quarantine"
			reason:      "old graph vocabulary is not the transition factory object vocabulary"
		},
		{
			path:        "contracts/protocols"
			disposition: "quarantine"
			reason:      "old protocol sketches are not green-path factory authority"
		},
		{
			path:        "contracts/adapters"
			disposition: "quarantine"
			reason:      "adapter-boundary vocabulary remains outside the worker aperture"
		},
		{
			path:        "generated"
			disposition: "quarantine"
			reason:      "generated plugin artifacts are migration examples only"
		},
	]
	delete: [
		{
			path:        ".repo"
			disposition: "delete"
			reason:      "repo-wide inventory artifacts are outside the factory pruning surface"
		},
		{
			path:        "cue.mod"
			disposition: "delete"
			reason:      "repo-root CUE module must not define global semantic authority"
		},
		{
			path:        "contracts/vcs"
			disposition: "delete"
			reason:      "raw VCS authority models are replaced by GitButler worker evidence"
		},
		{
			path:        "contracts/agent-runtime/adapters/codex_sdk.cue"
			disposition: "delete"
			reason:      "raw SDK authority models are excluded from the green path"
		},
	]
}
