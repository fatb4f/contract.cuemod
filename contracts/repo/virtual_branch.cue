package repo

#BranchName: string & =~"^[a-z0-9][a-z0-9-]*$"

#virtualBranchSchema: {
	id:         string & !=""
	branchName: #BranchName
	component:  #ComponentID
	temporary:  bool
	owns: [#OwnedPath, ...#OwnedPath]
	dependsOn: [...#ComponentID]
	allowedGlue: [...#GlueAllowance]
	mergeGate:              #MergeGate
	removalOrPromotionGate: #PromotionOrRemovalGate
}

// #VirtualBranch is the reusable schema downstream branches consume.
#VirtualBranch: close({
	#virtualBranchSchema
	temporary: false
})

// #VirtualBranchSeed is restricted to temporary bootstrap instances.
#VirtualBranchSeed: close({
	#virtualBranchSchema
	temporary: true
})
