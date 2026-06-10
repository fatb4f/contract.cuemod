#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
schema="$repo_root/agent.search.schema.cue"
valid="$repo_root/test/fixtures/stage3/valid"
invalid="$repo_root/test/fixtures/stage3/invalid"

fail() {
	printf 'stage3-schema: %s\n' "$*" >&2
	exit 1
}

require_file() {
	[ -f "$1" ] || fail "required file is missing: ${1#"$repo_root"/}"
}

vet_valid() {
	definition=$1
	fixture=$2
	(
		cd "$repo_root"
		cue vet -c -d "$definition" . "$fixture"
	)
}

vet_invalid() {
	definition=$1
	fixture=$2
	if (
		cd "$repo_root"
		cue vet -c -d "$definition" . "$fixture"
	) >/dev/null 2>&1; then
		fail "invalid fixture unexpectedly passed: ${fixture#"$repo_root"/}"
	fi
}

response_invariants_hold() {
	fixture=$1

	jq -e '
		.pagination.returned == (.results | length) and
		.pagination.returned <= .pagination.result_limit
	' "$fixture" >/dev/null &&
		jq -e '
		.results as $actual |
		($actual | sort_by(
			[-.rank_tuple[0], -.rank_tuple[1], -.rank_tuple[2],
			 .path, .line, .id]
		)) as $expected |
		$actual == $expected
	' "$fixture" >/dev/null &&
		jq -e '
		([.results[].id] | unique) as $result_ids |
		[
			.model_delta.missing_relationships[]?.evidence_result_ids[]?
			| select(. as $id | $result_ids | index($id) | not)
		] | length == 0
	' "$fixture" >/dev/null
}

assert_response_invariants() {
	fixture=$1
	response_invariants_hold "$fixture" ||
		fail "response invariants failed: ${fixture#"$repo_root"/}"
}

require_file "$schema"
require_file "$valid/projection-identity.json"
require_file "$valid/search-request.read-only.json"
require_file "$valid/search-response.read-only.json"
require_file "$valid/search-response.model-delta.json"
require_file "$valid/search-response.truncated.json"

for fixture in "$valid"/*.json "$invalid"/*.json; do
	jq -e . "$fixture" >/dev/null
done

vet_valid '#ProjectionIdentityFixture' "$valid/projection-identity.json"
vet_valid '#SearchImplementationRequest' "$valid/search-request.read-only.json"
vet_valid '#SearchImplementationResponse' "$valid/search-response.read-only.json"
vet_valid '#SearchImplementationResponse' "$valid/search-response.model-delta.json"
vet_valid '#SearchImplementationResponse' "$valid/search-response.truncated.json"

vet_invalid '#SearchImplementationRequest' "$invalid/projection-id-malformed.json"
vet_invalid '#SearchImplementationRequest' "$invalid/request-path-field.json"
vet_invalid '#SearchImplementationRequest' "$invalid/result-limit-exceeded.json"
vet_invalid '#SearchImplementationResponse' "$invalid/argv-string.json"
vet_invalid '#SearchImplementationResponse' "$invalid/evidence-id-malformed.json"
vet_invalid '#SearchImplementationResponse' "$invalid/model-delta-missing-reference.json"
vet_invalid '#SearchImplementationResponse' "$invalid/shell-command-field.json"
vet_invalid '#SearchImplementationError' "$invalid/rejection-code-unknown.json"
vet_invalid '#SearchImplementationResponse' "$invalid/truncation-inconsistent.json"

assert_response_invariants "$valid/search-response.read-only.json"
assert_response_invariants "$valid/search-response.model-delta.json"
assert_response_invariants "$valid/search-response.truncated.json"

if response_invariants_hold "$invalid/ordering-inconsistent.json"; then
	fail "invalid ordering fixture unexpectedly passed"
fi

identity="$valid/projection-identity.json"
expected_hash=$(jq -r '.projection_id | sub("^sha256:"; "")' "$identity")
actual_hash=$(
	jq -cS '.envelope' "$identity" |
		tr -d '\n' |
		sha256sum |
		cut -d ' ' -f 1
)
[ "$actual_hash" = "$expected_hash" ] ||
	fail "projection identity does not match canonical JSON: expected $expected_hash, got $actual_hash"

printf 'stage3-schema: ok\n'
