#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
cd "$repo_root"

tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/contract-repo-layout.XXXXXX")
trap 'rm -rf "$tmp_root"' EXIT HUP INT TERM

cue export ./projections/repo -e manifest >"$tmp_root/manifest.json"
cue export ./projections/repo -e inventory >"$tmp_root/inventory.json"
cue export ./projections/repo -e layoutMarkdown --out text >"$tmp_root/layout.md"

cmp "$tmp_root/manifest.json" .repo/manifest.json
cmp "$tmp_root/inventory.json" .repo/inventory.json
cmp "$tmp_root/layout.md" .repo/layout.md

if [ -e contract ]; then
	printf '%s\n' "singular authority root must not exist" >&2
	exit 1
fi

if rg -n \
	--glob '*.cue' \
	--glob '*.md' \
	--glob '*.sh' \
	--glob 'justfile' \
	'github\.com/fatb4f/contract\.cuemod/contract/|`(\./|\.\./)?contract/' \
	. >/dev/null; then
	printf '%s\n' "singular authority-root reference found" >&2
	exit 1
fi

find . -mindepth 1 -maxdepth 1 \
	! -name .git \
	-printf '%f\n' |
	sort >"$tmp_root/actual"

jq -r '.[].path | sub("/$"; "")' "$tmp_root/inventory.json" |
	sort >"$tmp_root/declared"

if ! diff -u "$tmp_root/declared" "$tmp_root/actual"; then
	printf '%s\n' "top-level repository inventory differs from projections/repo" >&2
	exit 1
fi

if find adapters -type d -name .git -print -quit | grep -q .; then
	printf '%s\n' "managed adapter contains nested Git metadata" >&2
	exit 1
fi

if rg -n --glob '.codex/hooks.json' --glob '.codex/skills/**/SKILL.md' '(^|/)bin/' .codex; then
	printf '%s\n' "generated agent assets reference repo-level bin/" >&2
	exit 1
fi

printf '%s\n' "repo layout checks: ok"
