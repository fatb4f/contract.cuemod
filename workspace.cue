package workspace

contractVersion: "0.2.0"

srcRoot:      "/home/_404/src"
contractRoot: "\(srcRoot)/contract.cuemod"

generated: {
	hosts:    "\(contractRoot)/workspace.hosts.json"
	projects: "\(contractRoot)/workspace.projects.json"
	domains:  "\(contractRoot)/workspace.domains.json"
	workflow: "\(contractRoot)/workspace.workflow.json"
	all:      "\(contractRoot)/workspace.contract.json"
}
