#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
generated_dir="$repo_root/generated/agent-context-resolver"
resolver_main="$repo_root/seeds/contract-cuemod/agent-context-resolver/cmd/seed-resolver/main.go"
valid_fixture="$repo_root/seeds/contract-cuemod/agent-context-resolver/fixtures/prompt_classification.valid.cue"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
cd "$repo_root"

fail() {
	printf '%s\n' "$*" >&2
	return 1
}

validate_registry_paths() {
	local registry_path="$1"
	local declared_path

	while IFS= read -r declared_path; do
		if [[ ! -e "$repo_root/$declared_path" ]]; then
			fail "missing registry path: $declared_path"
			return 1
		fi
	done < <(
		jq -r '
			.contracts[]
			| .authorityRoot, .contractPath, (.fragments[].sourcePath)
		' "$registry_path" | sort -u
	)
}

validate_reference_glue() {
	local component_path="$1"
	local referenced_path

	while IFS= read -r referenced_path; do
		if ! jq -e --arg path "$referenced_path" '
			[.owns[], (.allowedGlue[]?.paths[]?)]
			| index($path) != null
		' "$component_path" >/dev/null; then
			fail "undeclared vb-reference glue path: $referenced_path"
			return 1
		fi
	done < <(
		cd "$repo_root"
		rg -l --glob '*.cue' -F 'vb-reference' contracts | sort
	)
}

registry_path="$tmp_root/registry.index.json"
component_path="$tmp_root/reference-component.json"

cue export ./contracts/registry.cue \
	-e repoRegistry \
	--force \
	--out json \
	--outfile "$registry_path"
cue export ./contracts/vb-reference \
	-e referenceComponent \
	--force \
	--out json \
	--outfile "$component_path"

jq -e '
	.contracts[]
	| select(.id == "vb-reference")
	| .authorityRoot == "contracts/vb-reference"
		and .contractPath == "contracts/vb-reference/contract.cue"
		and ([.fragments[].id] == [
			"vb-reference.authority",
			"vb-reference.virtual-branch"
		])
' "$registry_path" >/dev/null

validate_registry_paths "$registry_path"
validate_reference_glue "$component_path"

regenerated_dir="$tmp_root/regenerated"
mkdir -p "$regenerated_dir"
cp "$registry_path" "$regenerated_dir/registry.index.json"
go run "$resolver_main" generate \
	--registry "$regenerated_dir/registry.index.json" \
	--out "$regenerated_dir"
diff -ru "$generated_dir" "$regenerated_dir"

undeclared_glue_component="$tmp_root/undeclared-glue-component.json"
jq '.allowedGlue = []' "$component_path" >"$undeclared_glue_component"
if validate_reference_glue "$undeclared_glue_component" >/dev/null 2>&1; then
	fail "vb-reference validation accepted undeclared registry glue"
	exit 1
fi

stale_generated_dir="$tmp_root/stale-generated"
mkdir -p "$stale_generated_dir"
cp "$generated_dir"/*.json "$stale_generated_dir/"
jq '
	(.fragments[] | select(.id == "vb-reference.authority").summary) =
		"stale generated fragment"
' "$stale_generated_dir/fragment_inventory.json" \
	>"$stale_generated_dir/fragment_inventory.json.tmp"
mv "$stale_generated_dir/fragment_inventory.json.tmp" \
	"$stale_generated_dir/fragment_inventory.json"

if output="$(
	go run "$resolver_main" validate \
		--generated "$stale_generated_dir" \
		--valid-fixture "$valid_fixture" 2>&1
)"; then
	fail "resolver validation accepted a stale generated fragment inventory"
	exit 1
fi
if [[ "$output" != *"fragment inventory is not the registry projection"* ]]; then
	fail "unexpected stale projection failure: $output"
	exit 1
fi

printf '%s\n' "vb-reference workflow checks: ok"
