package repo

#ComponentID: string & =~"^[a-z0-9][a-z0-9-]*$"

#OwnedPath: string & !="" & !~"^/" & !~"(^|/)\\.\\.(/|$)"

#LifecycleGate: close({
	scope: "merge-readiness" | "promotion-or-removal-readiness" | "glue-removal-readiness"
	state: "pending" | "passed" | "blocked"
	criteria: [string & !="", ...(string & !="")]
	evidence?: [...string & !=""]
})

#MergeGate: #LifecycleGate & {
	// This gate answers whether the branch or component can merge now.
	scope: "merge-readiness"
}

#PromotionOrRemovalGate: #LifecycleGate & {
	// This gate is evaluated after bootstrap use, not as a merge prerequisite.
	scope: "promotion-or-removal-readiness"
}

#GlueRemovalGate: #LifecycleGate & {
	scope: "glue-removal-readiness"
}

#GlueAllowance: close({
	id: string & !=""
	paths: [#OwnedPath, ...#OwnedPath]
	reason:      string & !=""
	removalGate: #GlueRemovalGate
})

#componentSchema: {
	id:        string & !=""
	component: #ComponentID
	owns: [#OwnedPath, ...#OwnedPath]
	dependsOn: [...#ComponentID]
	allowedGlue: [...#GlueAllowance]
	mergeGate:              #MergeGate
	removalOrPromotionGate: #PromotionOrRemovalGate
}

// #Component is the reusable schema downstream components consume.
#Component: close({
	#componentSchema
})

// #ComponentSeed is restricted to temporary bootstrap instances.
#ComponentSeed: close({
	#componentSchema
	temporary: true
})
