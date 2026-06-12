#!/usr/bin/env bash
set -euo pipefail

seed_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out_dir="${1:-"$seed_root/generated"}"

mkdir -p "$out_dir"

cue export \
  "$seed_root/contract/registry.cue" \
  -e repoRegistry \
  --force \
  --out json \
  --outfile "$out_dir/registry.index.json"

go run "$seed_root/cmd/seed-resolver/main.go" generate \
  --registry "$out_dir/registry.index.json" \
  --out "$out_dir"
