package workspace

import "list"

#ProjectionID:       string & =~"^sha256:[0-9a-f]{64}$"
#EvidenceID:         string & =~"^ev_[a-z2-7]{16}$"
#DeltaID:            string & =~"^delta_[a-z2-7]{16}$"
#SearchRelativePath: string & !~"^/" & !~"(^|/)\\.\\.(/|$)"

#SearchRejectionCode:
	"projection_not_found" |
	"projection_hash_mismatch" |
	"path_out_of_scope" |
	"expansion_forbidden" |
	"term_not_allowed" |
	"invalid_search_contract" |
	"result_limit_exceeded" |
	"backend_unavailable" |
	"backend_failed"

#ProjectionEnvelope: {
	schema:                    "agent.projection-envelope.v1"
	projection_schema_version: "agent.context-projection.v1"
	projection:                #AgentContextProjection
	search_policy_version:     "agent.search-policy.v1"
	ranking_policy_version:    "agent.ranking-policy.v1"
}

#ProjectionIdentityFixture: {
	schema:   "agent.projection-identity.fixture.v1"
	envelope: #ProjectionEnvelope
	canonicalization: {
		format: "jq-canonical-json"
		command: ["jq", "-cS", ".envelope"]
		newline:  "stripped"
		encoding: "utf-8"
		hash:     "sha256"
	}
	projection_id: #ProjectionID
}

#ProjectionLookupRequest: close({
	schema:        "agent.projection-lookup.request.v1"
	projection_id: #ProjectionID
})

#ProjectionLookupResponse: close({
	schema:        "agent.projection-lookup.response.v1"
	projection_id: #ProjectionID
	envelope:      #ProjectionEnvelope
})

#SearchPolicy: close({
	schema:  "agent.search-policy.v1"
	version: "agent.search-policy.v1"
	backend: "rg"
	result_limit: {
		min: 1
		max: 1000
	}
	path: {
		absolute_forbidden:                 true
		parent_escape_forbidden:            true
		expansion_requires_projection_root: true
	}
	terms: {
		non_empty:   true
		source:      "request"
		allow_regex: bool
	}
})

#SearchImplementationRequest: close({
	schema:        "agent.search-implementation.request.v1"
	projection_id: #ProjectionID
	intent:        string & !=""
	terms: [...string & !=""] & [_, ...]
	result_limit: int & >=1 & <=1000
})

#RankingPolicy: {
	schema:  "agent.ranking-policy.v1"
	version: "agent.ranking-policy.v1"
	sort: [
		"rank_tuple desc",
		"path asc",
		"line asc",
		"id asc",
	]
	evidence_id: {
		semantic:  "raw-match-span-id"
		algorithm: "sha256"
		encoding:  "base32-lower-no-padding"
		length:    16
		fields: [
			"projection_id",
			"path",
			"line",
			"column",
			"matched_text",
		]
		separator: "NUL"
		prefix:    "ev_"
	}
}

#SearchRankTuple: [
	number & >=0 & <=1,
	int & >=0,
	int & >=0,
]

#SearchExecution: close({
	backend:         "rg"
	backend_version: string & =~"^ripgrep [0-9]+\\."
	argv: ["rg", ...string]
	shell: false
	searched_paths: [...#SearchRelativePath] & [_, ...]
})

#SearchExecutionPlan: close({
	backend: "rg"
	argv: ["rg", ...string]
	shell: false
	searched_paths: [...#SearchRelativePath] & [_, ...]
})

#SearchPagination: {
	result_limit: int & >=1 & <=1000
	returned:     int & >=0 & <=result_limit
	truncated:    bool
	next_cursor:  string | null

	if truncated {
		returned:    result_limit
		next_cursor: string & !=""
	}
	if !truncated {
		next_cursor: null
	}
}

#SearchOrdering: {
	policy: "agent.ranking-policy.v1"
	sort: [
		"rank_tuple desc",
		"path asc",
		"line asc",
		"id asc",
	]
}

#SearchResult: {
	id:           #EvidenceID
	rank_tuple:   #SearchRankTuple
	kind:         "entrypoint" | "related_component" | "source" | "generated" | "target" | "instruction_boundary"
	path:         #SearchRelativePath
	line:         int & >=1
	column:       int & >=1
	matched_text: string
	reason:       string & !=""
}

#ModelDeltaRelationship: {
	id:           #DeltaID
	relationship: string & !=""
	evidence_result_ids: [...#EvidenceID] & [_, ...]
}

#SearchModelDelta: {
	missing_relationships?: [...#ModelDeltaRelationship]
}

#SearchImplementationResponse: {
	schema:        "agent.search-implementation.response.v1"
	projection_id: #ProjectionID
	execution:     #SearchExecution
	pagination:    #SearchPagination
	ordering:      #SearchOrdering
	results: [...#SearchResult]
	model_delta?: #SearchModelDelta

	pagination: returned: len(results)

	let resultIDs = [for result in results {result.id}]
	if model_delta != _|_ {
		for relationship in model_delta.missing_relationships {
			for evidenceID in relationship.evidence_result_ids
			if !list.Contains(resultIDs, evidenceID) {
				_|_("model_delta evidence_result_ids must refer to returned results")
			}
		}
	}
}

#ProjectionNotFoundError: {
	schema:        "agent.search-implementation.error.v1"
	code:          "projection_not_found"
	message:       string & !=""
	projection_id: #ProjectionID
	details: {}
}

#ProjectionHashMismatchError: {
	schema:        "agent.search-implementation.error.v1"
	code:          "projection_hash_mismatch"
	message:       string & !=""
	projection_id: #ProjectionID
	details: {
		expected_projection_id: #ProjectionID
		actual_projection_id:   #ProjectionID
	}
}

#PathOutOfScopeError: {
	schema:        "agent.search-implementation.error.v1"
	code:          "path_out_of_scope"
	message:       string & !=""
	projection_id: #ProjectionID
	details: {
		requested_path: string
		allowed_roots: [...#SearchRelativePath]
	}
}

#ExpansionForbiddenError: {
	schema:        "agent.search-implementation.error.v1"
	code:          "expansion_forbidden"
	message:       string & !=""
	projection_id: #ProjectionID
	details: {
		requested_path: #SearchRelativePath
		allowed_roots: [...#SearchRelativePath]
	}
}

#TermNotAllowedError: {
	schema:        "agent.search-implementation.error.v1"
	code:          "term_not_allowed"
	message:       string & !=""
	projection_id: #ProjectionID
	details: {
		term: string
		allowed_terms: [...string]
	}
}

#InvalidSearchContractError: {
	schema:        "agent.search-implementation.error.v1"
	code:          "invalid_search_contract"
	message:       string & !=""
	projection_id: #ProjectionID
	details: {
		field?:  string
		reason?: string
	}
}

#ResultLimitExceededError: {
	schema:        "agent.search-implementation.error.v1"
	code:          "result_limit_exceeded"
	message:       string & !=""
	projection_id: #ProjectionID
	details: {
		requested: int & >=1
		maximum:   int & >=1
	}
}

#BackendUnavailableError: {
	schema:        "agent.search-implementation.error.v1"
	code:          "backend_unavailable"
	message:       string & !=""
	projection_id: #ProjectionID
	details: {
		backend: "rg"
	}
}

#BackendFailedError: {
	schema:        "agent.search-implementation.error.v1"
	code:          "backend_failed"
	message:       string & !=""
	projection_id: #ProjectionID
	details: {
		backend:   "rg"
		exit_code: int
		stderr?:   string
	}
}

#SearchImplementationError:
	#ProjectionNotFoundError |
	#ProjectionHashMismatchError |
	#PathOutOfScopeError |
	#ExpansionForbiddenError |
	#TermNotAllowedError |
	#InvalidSearchContractError |
	#ResultLimitExceededError |
	#BackendUnavailableError |
	#BackendFailedError

#SearchImplementationOutcome:
	#SearchImplementationResponse |
	#SearchImplementationError

searchPlanInput?: {
	envelope: #ProjectionEnvelope
	request:  #SearchImplementationRequest
}

if searchPlanInput != _|_ {
	let projectedSearchPaths = [
		for path in searchPlanInput.envelope.projection.scope.inspect {
			path
		},
	]
	let projectedTermArgs = list.Concat([
		for term in searchPlanInput.request.terms {
			["-e", term]
		},
	])

	searchExecutionPlan: #SearchExecutionPlan & {
		backend: "rg"
		argv: list.Concat([
			[
				"rg",
				"--json",
				"--line-number",
				"--column",
				"--smart-case",
				"--fixed-strings",
			],
			projectedTermArgs,
			["--"],
			projectedSearchPaths,
		])
		shell:          false
		searched_paths: projectedSearchPaths
	}
}
