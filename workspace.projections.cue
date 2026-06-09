package workspace

let manifestContractVersion = "0.2.0"
let manifestSrcRoot = "/home/_404/src"
let manifestContractRoot = "/home/_404/src/contract.cuemod"

hostManifest: #HostsProjection & {
	version:         "workspace.hosts.v1"
	contractVersion: manifestContractVersion
	srcRoot:         manifestSrcRoot
	contractRoot:    manifestContractRoot
	hosts: [
		for _, host in hostWorkspaces {
			host
		},
	]
}

projectManifest: #ProjectsProjection & {
	version:         "workspace.projects.v1"
	contractVersion: manifestContractVersion
	srcRoot:         manifestSrcRoot
	contractRoot:    manifestContractRoot
	projects: [
		for _, project in projectSessions {
			project
		},
	]
}

domainManifest: #DomainsProjection & {
	version:         "workspace.domains.v1"
	contractVersion: manifestContractVersion
	srcRoot:         manifestSrcRoot
	contractRoot:    manifestContractRoot
	domains: [
		for _, domain in dotfilesDomains {
			domain
		},
	]
}

workflowManifest: #WorkflowProjection & {
	version:         "workspace.workflow.v1"
	contractVersion: manifestContractVersion
	srcRoot:         manifestSrcRoot
	contractRoot:    manifestContractRoot
	workflow:        workflowPolicy
}

contractManifest: #ContractProjection & {
	version:         "workspace.contract.v1"
	contractVersion: manifestContractVersion
	srcRoot:         manifestSrcRoot
	contractRoot:    manifestContractRoot
	hosts:           hostManifest.hosts
	projects:        projectManifest.projects
	domains:         domainManifest.domains
	workflow:        workflowManifest.workflow
}
