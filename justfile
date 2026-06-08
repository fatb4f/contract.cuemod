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

archive:
  tar --exclude=.git -czf ../contract.cuemod.tar.gz -C .. contract.cuemod
