set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

export:
	cue export . -e hostManifest --out json > workspace.hosts.json
	cue export . -e projectManifest --out json > workspace.projects.json
	cue export . -e domainManifest --out json > workspace.domains.json
	cue export . -e workflowManifest --out json > workspace.workflow.json
	cue export . -e contractManifest --out json > workspace.contract.json

validate:
	cue vet .
	python3 scripts/validate_json.py

check: validate

archive:
	tar --exclude=.git -czf ../contract.cuemod.tar.gz -C .. contract.cuemod
