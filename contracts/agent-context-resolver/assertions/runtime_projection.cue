package assertions

import runtimeprojection "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver/projections/agent-runtime:runtimeprojection"

runtimeProjectionAssertions: {
	projection: runtimeprojection.domain & {
		authority:   false
		extractable: false
		imports: ["agent-context-resolver", "agent-runtime"]
	}

	routeResultsAreAuthority: false
}
