package assertions

import agentprojection "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver/projections/agent-skill:agentskillprojection"

codexPluginAssertions: {
	projectionAuthority: false
	extractable:         false

	hooks:        agentprojection.projection.hooks
	skillContent: agentprojection.skillContent
}
