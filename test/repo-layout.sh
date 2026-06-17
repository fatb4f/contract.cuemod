#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
cd "$repo_root"

cue export ./contracts/repo/assertions \
	-e repoLayoutAssertions \
	>/dev/null
