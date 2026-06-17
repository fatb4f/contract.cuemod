package assertions

import resolverprojections "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver/projections:projections"

projectionBoundaryAssertions: {
	section: resolverprojections.section & {
		id:   "agent-context-resolver.projections"
		kind: "projections"
		path: "projections"
	}

	authority:      false
	extractable:    false
	rootRegistered: false
}
