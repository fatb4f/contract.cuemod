package extraction

#TransitionState:
	"S0 EmbeddedFactory" |
	"S1 SealedFactorySurface" |
	"S2 ExportedFactoryTransitionPacket" |
	"S3 DedicatedRepoSeeded" |
	"S4 AuthorityRebound" |
	"S5 ParityValidated" |
	"S6 SourceRepoDetached" |
	"S7 UpstreamMonitorAttached" |
	"S8 DedicatedFactoryStable"

#SurfaceLock: close({
	schema: "factory.extraction-surface-lock.v1"
	issue:  "#67"
	state:  "S1 SealedFactorySurface"
	source: close({
		repository: "fatb4f/contract.cuemod"
		branch:     "factory/reflective-transition-factory"
	})
	target: close({
		repository: "fatb4f/factory"
		pathPolicy: "preserve contracts/factory path; no flattening during extraction"
	})
	activeAuthority: close({
		root: "contracts/factory"
		requiredPaths: [
			"contracts/factory/adapters",
			"contracts/factory/assertions",
			"contracts/factory/docs",
			"contracts/factory/fixtures",
			"contracts/factory/object",
			"contracts/factory/transition",
			"contracts/factory/workers",
		]
	})
	boundedInputs: [
		"contracts/agent-runtime",
		"contracts/agent-context-resolver",
	]
	nonAuthorityEvidence: [
		"migration/legacy",
	]
	gateInvariants: [
		"No destructive move/delete without a sealed surface lock.",
		"No repo materialization without an admitted transition packet.",
		"No target authority without parity validation.",
		"No contract.cuemod detach before target repo validates.",
		"No future factory issue remains under contract.cuemod after handoff.",
	]
})

surfaceLock: #SurfaceLock
