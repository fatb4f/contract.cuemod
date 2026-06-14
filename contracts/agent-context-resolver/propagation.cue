package agentcontextresolver

#BoundaryIncludes: close({
	objective: string & !=""
	acceptedFacts: [...string]
	selectedFragments: [...#DeclaredID]
	files: [...string]
	priorArtifacts?: [...string]
	validationCommands?: [...string]
})

#BoundaryReturn: close({
	schema:            #RouteOutputSchema
	maxSummaryTokens?: int & >0
	evidenceRequired:  bool
})

#RouteContextBoundary: close({
	includes: #BoundaryIncludes
	excludes: [
		"full transcript",
		"unselected fragments",
		"raw registry",
		"unbounded tool logs",
		"irrelevant route outputs",
	]
	return: #BoundaryReturn
})

#RootContextBoundary: close({
	includes: close({
		intent: #PromptIntent
		selectedFragments: [...#DeclaredID]
		acceptedRouteResults: [...#DeclaredID]
	})
	excludes: [
		"raw route logs",
		"unvalidated route claims",
		"runtime implementation details",
	]
})

#PropagationPlan: close({
	mode: "route-local"
	root: #RootContextBoundary
	perRoute: [#DeclaredID]: #RouteContextBoundary
	denyFullTranscript:      true
	denyRawRegistryDump:     true
	denyUnselectedFragments: true
	requireStructuredResult: true
})
