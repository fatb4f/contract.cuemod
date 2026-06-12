package repo

#ComponentID: string & =~"^[a-z0-9][a-z0-9-]*$"

#OwnedPath: string & !="" & !~"^/" & !~"(^|/)\\.\\.(/|$)"

#LifecycleGate: close({
	state: "pending" | "passed" | "blocked"
	criteria: [string & !="", ...(string & !="")]
	evidence?: [...string & !=""]
})

#GlueAllowance: close({
	id: string & !=""
	paths: [#OwnedPath, ...#OwnedPath]
	reason:      string & !=""
	removalGate: #LifecycleGate
})

#ComponentSeed: close({
	id:        string & !=""
	component: #ComponentID
	owns: [#OwnedPath, ...#OwnedPath]
	dependsOn: [...#ComponentID]
	allowedGlue: [...#GlueAllowance]
	mergeGate:              #LifecycleGate
	temporary:              true
	removalOrPromotionGate: #LifecycleGate
})
