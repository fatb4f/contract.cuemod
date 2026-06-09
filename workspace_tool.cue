package workspace

import (
	"encoding/json"
	"tool/cli"
	"tool/exec"
	"tool/file"
)

command: export: {
	hosts: file.Create & {
		filename: generated.hosts
		contents: json.Marshal(hostManifest)
	}

	projects: file.Create & {
		filename: generated.projects
		contents: json.Marshal(projectManifest)
	}

	domains: file.Create & {
		filename: generated.domains
		contents: json.Marshal(domainManifest)
	}

	workflow: file.Create & {
		filename: generated.workflow
		contents: json.Marshal(workflowManifest)
	}

	contract: file.Create & {
		filename: generated.all
		contents: json.Marshal(contractManifest)
	}

	done: cli.Print & {
		text: "exported workspace projections"
	}
}

command: validate: {
	cueVet: exec.Run & {
		cmd: "cue vet ."
	}

	hosts: exec.Run & {
		$after: [cueVet]
		cmd: "cue vet . workspace.hosts.json -d=#HostsProjection"
	}

	projects: exec.Run & {
		$after: [hosts]
		cmd: "cue vet . workspace.projects.json -d=#ProjectsProjection"
	}

	domains: exec.Run & {
		$after: [projects]
		cmd: "cue vet . workspace.domains.json -d=#DomainsProjection"
	}

	workflow: exec.Run & {
		$after: [domains]
		cmd: "cue vet . workspace.workflow.json -d=#WorkflowProjection"
	}

	contract: exec.Run & {
		$after: [workflow]
		cmd: "cue vet . workspace.contract.json -d=#ContractProjection"
	}

	done: cli.Print & {
		$after: [contract]
		text: "validated workspace projections"
	}
}

command: check: {
	export: exec.Run & {
		cmd: "cue cmd export"
	}

	validate: exec.Run & {
		$after: [export]
		cmd: "cue cmd validate"
	}

	diff: exec.Run & {
		$after: [validate]
		cmd: "git diff --exit-code -- workspace.*.json"
	}

	done: cli.Print & {
		$after: [diff]
		text: "workspace contract check passed"
	}
}
