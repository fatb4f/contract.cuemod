package workspace

import "list"

#ProjectionID:       string & =~"^sha256:[0-9a-f]{64}$"
#EvidenceID:         string & =~"^ev_[a-z2-7]{16}$"
#DeltaID:            string & =~"^delta_[a-z2-7]{16}$"
#SearchRelativePath: string & !~"^/" & !~"(^|/)\\.\\.(/|$)"
#GraphID:            string & =~"^df:[a-z]+/[a-z0-9._-]+$"

#ProviderID:
	"df:provider/cue-rg-mcp" |
	"df:provider/cue-lsp-mcp" |
	"df:provider/lua-lsp-mcp"

#Provider: close({
	id:      #ProviderID
	kind:    "cue-search" | "cue-lsp" | "lua-lsp"
	plane:   "evidence" | "contract-semantics" | "implementation-semantics"
	adapter: "native-mcp" | "lsp-backed-mcp"
	server?: string
	type_libraries?: [...string & !=""]
	capabilities: [...string & !=""] & [_, ...]
})

stage3Providers: [#ProviderID]: #Provider
stage3Providers: {
	"df:provider/cue-rg-mcp": {
		id:      "df:provider/cue-rg-mcp"
		kind:    "cue-search"
		plane:   "evidence"
		adapter: "native-mcp"
		capabilities: ["search", "bounded-rg", "artifact-filter", "raw-evidence"]
	}
	"df:provider/cue-lsp-mcp": {
		id:      "df:provider/cue-lsp-mcp"
		kind:    "cue-lsp"
		plane:   "contract-semantics"
		adapter: "lsp-backed-mcp"
		server:  "cue lsp"
		capabilities: ["definition", "references", "hover", "diagnostics", "document-symbols"]
	}
	"df:provider/lua-lsp-mcp": {
		id:      "df:provider/lua-lsp-mcp"
		kind:    "lua-lsp"
		plane:   "implementation-semantics"
		adapter: "lsp-backed-mcp"
		server:  "lua-language-server"
		type_libraries: ["wezterm-types"]
		capabilities: ["definition", "references", "hover", "diagnostics", "document-symbols"]
	}
}

#SemanticProvidersResponse: close({
	schema: "agent.semantic-providers.response.v1"
	providers: [#ProviderID]: #Provider
})

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
	artifact_ids: [...#GraphID] & [_, ...]
	intent: string & !=""
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
	provider_id:     "df:provider/cue-rg-mcp"
	backend:         "rg"
	backend_version: string & =~"^ripgrep [0-9]+\\."
	shell:           false
	invocations: [...{
		artifact_id: #GraphID
		argv: ["rg", ...string]
		path: #SearchRelativePath
	}] & [_, ...]
})

#SearchExecutionPlan: close({
	backend: "rg"
	shell:   false
	terms: [...string & !=""] & [_, ...]
	targets: [...{
		artifact_id: #GraphID
		path:        #SearchRelativePath
	}] & [_, ...]
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
	evidence_id:  #EvidenceID
	provider_id:  "df:provider/cue-rg-mcp"
	artifact_id:  #GraphID
	symbol_id?:   #GraphID
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
	coverage: {
		selected_artifacts: [...#GraphID] & [_, ...]
		searched_artifacts: [...#GraphID] & [_, ...]
		truncated:              bool
		negative_claim_allowed: false
		reason:                 string & !=""
	}
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
	let projectedArtifacts = [
		for artifact in searchPlanInput.envelope.projection.artifacts
		if list.Contains(searchPlanInput.request.artifact_ids, artifact.id) {
			artifact
		},
	]

	searchExecutionPlan: #SearchExecutionPlan & {
		backend: "rg"
		shell:   false
		terms:   searchPlanInput.request.terms
		targets: [
			for artifact in projectedArtifacts {
				artifact_id: artifact.id
				path:        artifact.path
			},
		]
		if len(projectedArtifacts) != len(searchPlanInput.request.artifact_ids) {
			_|_("every requested artifact_id must resolve in the projection")
		}
	}
}
