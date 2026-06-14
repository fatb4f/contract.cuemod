set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

check:
  ./test/check.sh

fmt:
  cue fmt ./contracts/... ./providers/... ./projections/... ./fixtures/...

archive:
  tar --exclude=.git -czf ../contract.cuemod.tar.gz -C .. contract.cuemod
