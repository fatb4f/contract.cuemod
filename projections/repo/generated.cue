package repo

generated: manifest.generatedAssets

layoutMarkdown: """
	<!-- Code generated from contracts/repo and projections/repo. DO NOT EDIT. -->

	# Repository Layout

	| Surface | Role | Lifecycle | Authority |
	| --- | --- | --- | --- |
	| `contracts/` | authority | source | authoritative |
	| `providers/` | provider | source | authoritative |
	| `adapters/` | adapter | managed-snapshot | non-authority |
	| `projections/` | projection | source | derived |
	| `fixtures/` | fixture | test-fixture | non-authority |
	| `generated/` | generated | generated | derived |
	| `migration/` | migration | quarantine | quarantined |
	| `test/` | validation | source | non-authority |
	| `docs/` | documentation | source | non-authority |
	| `.codex/` | generated | generated | derived |
	| `.repo/` | generated | generated | derived |
	| `cmd/` | tooling | source | non-authority |
	| `internal/` | tooling | source | non-authority |
	| `bin/` | tooling | source | non-authority |
	| `cue.mod/` | tooling | source | authoritative |
	"""
