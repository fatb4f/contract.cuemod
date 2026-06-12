package repo

#BranchName: string & =~"^[a-z0-9][a-z0-9-]*$"

#VirtualBranchSeed: close({
	id:         string & !=""
	branchName: #BranchName
	component:  #ComponentID
	owns: [#OwnedPath, ...#OwnedPath]
	dependsOn: [...#ComponentID]
	allowedGlue: [...#GlueAllowance]
	mergeGate:              #LifecycleGate
	temporary:              true
	removalOrPromotionGate: #LifecycleGate
})
