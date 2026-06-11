package repo

#SurfaceRole: "authority" | "provider" | "adapter" | "projection" | "fixture" | "migration" | "validation" | "documentation" | "tooling" | "generated"

#AuthorityStatus: "authoritative" | "derived" | "non-authority" | "quarantined" | "legacy"

#RepoSurface: close({
	path:        string & =~"^[^/]+/$"
	kind:        "directory"
	role:        #SurfaceRole
	lifecycle:   #Lifecycle
	authority:   #AuthorityStatus
	generated:   bool
	owner:       string & !=""
	description: string & !=""

	allowedFileKinds: *["file", "directory"] | [...("file" | "directory")]
	allowedImports: *[] | [...string]
	allowedExtensions?: [...string]
	allowedChildren?: [...string]
	forbiddenChildren?: [...string]
	validatesWith: [...string & !=""] & [_, ...]
	prunesWith: *["reject undeclared children"] | [...string & !=""]
	replacement?: string & =~"^[^/]+/$"

	if lifecycle == "deprecated" {
		authority:   "legacy"
		replacement: string
	}
	if generated {
		lifecycle: "generated"
		authority: "derived"
	}
})
