package repo

#InventoryEntry: close({
	path:      string & !=""
	kind:      "directory" | "file"
	role:      #SurfaceRole
	lifecycle: #Lifecycle
	authority: #AuthorityStatus
	generated: bool
	owner:     string & !=""
	validatesWith: [...string & !=""] & [_, ...]
	status: "declared" | "legacy" | "generated"
})
