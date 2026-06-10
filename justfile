set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

default:
  just --choose

export:
  cue cmd export

validate:
  cue cmd validate

check:
  cue cmd check

fmt:
  cue fmt .

list:
  cue cmd -l

agent-hooks:
  mkdir -p /home/_404/src/dotfiles/.codex
  cue export . dotfiles.schema-map.json -e codexHooks --out json > /home/_404/src/dotfiles/.codex/hooks.json

agent-context-test:
  ./test/agent-context-hook.sh

archive:
  tar --exclude=.git -czf ../contract.cuemod.tar.gz -C .. contract.cuemod
