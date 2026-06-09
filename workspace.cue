package workspace

// Root contract constants. These are intentionally static: adapters consume
// projections and must not discover project roots at runtime.
contractVersion: "0.2.0"
srcRoot:         "/home/_404/src"
contractRoot:    "\(srcRoot)/contract.cuemod"

generated: {
	hosts:    "workspace.hosts.json"
	projects: "workspace.projects.json"
	domains:  "workspace.domains.json"
	workflow: "workspace.workflow.json"
	all:      "workspace.contract.json"
}
