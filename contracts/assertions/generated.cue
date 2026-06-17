package assertions

import resolvgenerated "github.com/fatb4f/contract.cuemod/contracts/agent-context-resolver/generated:generated"

generatedAssertionSurface: {
	resolverGeneratedSection: resolvgenerated.section & {
		id:   "agent-context-resolver.generated"
		kind: "generated"
		path: "generated"
	}

	authority:                     "cue-assertions"
	generatedArtifactsAreEvidence: true
	shellScriptIsAuthority:        false
}
