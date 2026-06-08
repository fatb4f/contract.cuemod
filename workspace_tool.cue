package workspace

import (
	"encoding/json"
	"tool/file"
)

command: export: {
	hosts: file.Create & {
		filename: generated.hosts
		contents:  json.Marshal(hostManifest)
	}

	projects: file.Create & {
		filename: generated.projects
		contents:  json.Marshal(projectManifest)
	}

	domains: file.Create & {
		filename: generated.domains
		contents:  json.Marshal(domainManifest)
	}

	workflow: file.Create & {
		filename: generated.workflow
		contents:  json.Marshal(workflowManifest)
	}

	all: file.Create & {
		filename: generated.all
		contents:  json.Marshal(contractManifest)
	}
}
