package workspace

hostManifest: #HostsProjection & {
	version: "workspace.hosts.v1"
	contractVersion: contractVersion
	srcRoot: srcRoot
	contractRoot: contractRoot
	hosts: [
		for _, host in hostWorkspaces {
			host
		},
	]
}

projectManifest: #ProjectsProjection & {
	version: "workspace.projects.v1"
	contractVersion: contractVersion
	srcRoot: srcRoot
	contractRoot: contractRoot
	projects: [
		for _, project in projectSessions {
			project
		},
	]
}

domainManifest: #DomainsProjection & {
	version: "workspace.domains.v1"
	contractVersion: contractVersion
	srcRoot: srcRoot
	contractRoot: contractRoot
	domains: [
		for _, domain in dotfilesDomains {
			domain
		},
	]
}

workflowManifest: #WorkflowProjection & {
	version: "workspace.workflow.v1"
	contractVersion: contractVersion
	srcRoot: srcRoot
	contractRoot: contractRoot
	workflow: workflowPolicy
}

contractManifest: #ContractProjection & {
	version: "workspace.contract.v1"
	contractVersion: contractVersion
	srcRoot: srcRoot
	contractRoot: contractRoot
	hosts: hostManifest.hosts
	projects: projectManifest.projects
	domains: domainManifest.domains
	workflow: workflowManifest.workflow
}
