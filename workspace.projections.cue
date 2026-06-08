package workspace

hostManifest: {
	version:         "workspace.hosts.v1"
	contractVersion: contractVersion
	srcRoot:         srcRoot
	contractRoot:    contractRoot
	hosts: [
		for _, host in hostWorkspaces {
			id:       host.id
			label:    host.label
			root:     host.root
			intent:   host.intent
			surfaces: host.surfaces
		},
	]
}

projectManifest: {
	version:         "workspace.projects.v1"
	contractVersion: contractVersion
	srcRoot:         srcRoot
	contractRoot:    contractRoot
	projects: [
		for _, project in projectSessions {
			id:       project.id
			label:    project.label
			root:     project.root
			kind:     project.kind
			intent:   project.intent
			editor:   project.editor
			commands: project.commands
			env:      project.env
			adapters: project.adapters
		},
	]
}

domainManifest: {
	version:         "workspace.domains.v1"
	contractVersion: contractVersion
	srcRoot:         srcRoot
	contractRoot:    contractRoot
	domains: [
		for _, domain in dotfilesDomains {
			domain
		},
	]
}

workflowManifest: {
	version:         "workspace.workflow.v1"
	contractVersion: contractVersion
	srcRoot:         srcRoot
	contractRoot:    contractRoot
	workflow:        workflowPolicy
}

contractManifest: {
	version:         "workspace.contract.v1"
	contractVersion: contractVersion
	srcRoot:         srcRoot
	contractRoot:    contractRoot
	hosts:           hostManifest.hosts
	projects:        projectManifest.projects
	domains:         domainManifest.domains
	workflow:        workflowManifest.workflow
}
