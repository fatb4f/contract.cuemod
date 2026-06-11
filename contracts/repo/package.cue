package repo

#RepoPackage: close({
	path:      string & !=""
	owner:     string & !=""
	authority: #AuthorityStatus
	generated: bool
	allowedImports: [...string]
	forbiddenImports: [...string]
	validatesWith: [...string & !=""] & [_, ...]
})
