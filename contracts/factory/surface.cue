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
		{
			path:        "cmd"
			disposition: "keep"
			reason:      "current Go adapter entrypoints remain buildable"
		},
		{
			path:        "internal"
			disposition: "keep"
			reason:      "implementation support for current Go adapter entrypoints"
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
			path:        "migration/legacy/contracts/repo"
			disposition: "quarantine"
			reason:      "repo authority model is migration evidence, not factory authority"
		},
		{
			path:        "migration/legacy/contracts/vcs"
			disposition: "quarantine"
			reason:      "raw VCS authority models are replaced by GitButler worker evidence"
		},
		{
			path:        "migration/legacy/contracts/graph"
			disposition: "quarantine"
			reason:      "old graph vocabulary is not the transition factory object vocabulary"
		},
		{
			path:        "migration/legacy/contracts/protocols"
			disposition: "quarantine"
			reason:      "old protocol sketches are not green-path factory authority"
		},
		{
			path:        "migration/legacy/contracts/adapters"
			disposition: "quarantine"
			reason:      "adapter-boundary vocabulary remains outside the worker aperture"
		},
		{
			path:        "migration/legacy/generated/codex-plugin"
			disposition: "quarantine"
			reason:      "generated plugin artifacts are migration examples only"
		},
		{
			path:        "migration/legacy/fixtures"
			disposition: "quarantine"
			reason:      "legacy fixtures are retained as migration evidence only"
		},
		{
			path:        "migration/legacy/providers"
			disposition: "quarantine"
			reason:      "non-CUE providers are outside the factory worker aperture"
		},
		{
			path:        "migration/legacy/projections/repo"
			disposition: "quarantine"
			reason:      "repo projection is no longer a source authority root"
		},
		{
			path:        "migration/legacy/docs"
			disposition: "quarantine"
			reason:      "legacy VCS, plugin, and repo docs are migration evidence"
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
			path:        "fixtures"
			disposition: "delete"
			reason:      "top-level fixtures must be factory fixtures or migration evidence"
		},
		{
			path:        "generated"
			disposition: "delete"
			reason:      "top-level generated outputs must be factory projections or migration evidence"
		},
		{
			path:        "providers"
			disposition: "delete"
			reason:      "providers are worker aperture references or migration evidence"
		},
		{
			path:        "projections"
			disposition: "delete"
			reason:      "top-level projections are not independent authority roots"
		},
		{
			path:        "adapters"
			disposition: "delete"
			reason:      "top-level adapters are not independent authority roots"
		},
		{
			path:        "test"
			disposition: "delete"
			reason:      "top-level test scripts are replaced by factory pruning assertions"
		},
		{
			path:        "contracts/agent-runtime/adapters/codex_sdk.cue"
			disposition: "delete"
			reason:      "raw SDK authority models are excluded from the green path"
		},
	]
}
