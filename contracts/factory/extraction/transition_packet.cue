package extraction

import transition "github.com/fatb4f/contract.reflective-transition-factory/contracts/factory/transition"

extractionTransitionPacket: transition.#TransitionPacket & {
	schema: "factory.transition-packet.v1"
	runtimeEvents: [{
		id:      "migration/issue-68/runtime-event/source-sealed"
		schema:  "factory.runtime-event.v1"
		source:  "worker"
		summary: "Factory extraction surface was sealed before dedicated repository materialization."
	}]
	resolverSelections: [{
		id:     "migration/issue-68/resolver-selection/factory-authority"
		schema: "factory.resolver-selection.v1"
		source: "agent-context-resolver"
		selected: [
			"contracts/factory",
			"contracts/agent-runtime",
			"contracts/agent-context-resolver",
		]
		reason: "Migration selection is bounded to the active factory authority and declared runtime and resolver inputs."
	}]
	workerSelections: [{
		id:       "migration/issue-68/worker-selection/codex"
		schema:   "factory.worker-selection.v1"
		workerID: "codex"
		kind:     "codex"
		reason:   "Codex performs the admitted extraction as a bounded materialization worker."
	}]
	evidenceRequests: [{
		id:     "migration/issue-68/evidence-request/parity"
		schema: "factory.evidence-request.v1"
		worker: workerSelections[0]
		fixtures: [
			"migration/issue-68/fixture/no-raw-copy",
			"migration/issue-68/fixture/no-dual-authority",
		]
		question: "Seed the dedicated factory repo only after the sealed surface lock and validate parity before source detach."
	}]
	reflections: [{
		id:       "migration/issue-68/reflection/extraction-plan"
		schema:   "factory.worker-reflection.v1"
		workerID: "codex"
		kind:     "codex"
		summary:  "The extraction proceeds through sealed surface, admitted packet, target seed, authority rebound, parity validation, source detach, and monitor handoff."
		evidence: ["migration/issue-68/evidence/admitted-packet"]
	}]
	evidence: [{
		id:        "migration/issue-68/evidence/admitted-packet"
		schema:    "factory.evidence.v1"
		requestID: "migration/issue-68/evidence-request/parity"
		workerID:  "codex"
		kind:      "projection"
		summary:   "Transition packet encodes the migration gate order and target materialization bounds."
		bounds: {
			excludes: [
				"raw-diff",
				"raw-log",
				"full-repo-firehose",
			]
		}
	}]
	negativeFixtures: [
		{
			id:      "migration/issue-68/fixture/no-raw-copy"
			schema:  "factory.negative-fixture.v1"
			surface: "material"
			fails:   "A dedicated repository is materialized without an admitted transition packet."
			mustNotExpose: [
				"raw-diff",
				"raw-log",
				"full-repo-firehose",
			]
		},
		{
			id:      "migration/issue-68/fixture/no-dual-authority"
			schema:  "factory.negative-fixture.v1"
			surface: "semantic"
			fails:   "Both contract.cuemod and the dedicated factory repository present contracts/factory as active authority after parity validation."
			mustNotExpose: ["raw-git-topology"]
		},
	]
	candidates: [#candidate]
	evaluations: []
	feedback: []
	transitions: []
	materializations: []
}

extractionAdmission: close({
	schema:     "factory.extraction-admission.v1"
	issue:      "#68"
	state:      "S2 ExportedFactoryTransitionPacket"
	packet:     "extractionTransitionPacket"
	candidate:  #candidate.id
	admitted:   true
	nextState:  "S3 DedicatedRepoSeeded"
	gateReason: "The sealed surface lock exists, negative fixtures are declared, and materialization is bounded to fatb4f/factory."
	sourceCommitRequired: true
})

#candidate: {
	id:     "migration/issue-68/candidate/extract-factory"
	schema: "factory.candidate.v1"
	fixtures: [
		"migration/issue-68/fixture/no-raw-copy",
		"migration/issue-68/fixture/no-dual-authority",
	]
	evidence: ["migration/issue-68/evidence/admitted-packet"]
	intent:            "Extract reflective transition factory authority into fatb4f/factory while preserving path shape and bounded inputs."
	transitionSurface: "material"
}

#evaluation: {
	id:        "migration/issue-68/evaluation/extract-factory"
	schema:    "factory.evaluation.v1"
	candidate: #candidate
	verdicts: [
		{
			schema:    "factory.fixture-verdict.v1"
			fixtureID: "migration/issue-68/fixture/no-raw-copy"
			verdict:   "negated"
			evidence:  ["migration/issue-68/evidence/admitted-packet"]
			reason:    "The packet is committed before target repository materialization."
		},
		{
			schema:    "factory.fixture-verdict.v1"
			fixtureID: "migration/issue-68/fixture/no-dual-authority"
			verdict:   "negated"
			evidence:  ["migration/issue-68/evidence/admitted-packet"]
			reason:    "Source detach is gated behind target validation and parity certificate creation."
		},
	]
	assertions: [{
		id:      "migration/issue-68/assertion/gate-order"
		schema:  "factory.assertion-result.v1"
		name:    "migration gate order"
		passed:  true
		subject: "migration/issue-68/candidate/extract-factory"
		reason:  "Required transition states are represented in order by issues #67 through #73."
	}]
	passed: true
}

#feedback: {
	id:         "migration/issue-68/feedback/admit-extraction"
	schema:     "factory.feedback.v1"
	evaluation: #evaluation
	decision:   "admit"
	reason:     "The sealed surface and negative fixtures admit repository seeding as the next transition."
}

#admittedTransition: {
	id:       "migration/issue-68/transition/dedicated-repo-seed"
	schema:   "factory.transition.v1"
	feedback: #feedback
	admitted: true
	binds: {
		semantic:  "migration/issue-68/candidate/extract-factory"
		runtime:   "migration/issue-68/runtime-event/source-sealed"
		material:  "migration/issue-68/evidence/admitted-packet"
	}
}

#materialization: {
	id:         "migration/issue-68/materialization/target-repo"
	schema:     "factory.materialization.v1"
	transition: #admittedTransition
	workerID:   "codex"
	surface:    "material"
	summary:    "The target repository may now be seeded from the sealed factory authority and bounded input surfaces."
}
