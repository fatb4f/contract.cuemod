package repo

#RepoAsset: close({
	path:      string & =~"^[^/]+$"
	kind:      "file"
	role:      #SurfaceRole
	lifecycle: #Lifecycle
	authority: #AuthorityStatus
	generated: bool
	owner:     string & !=""
	validatesWith: [...string & !=""] & [_, ...]
})

#GeneratedAsset: close({
	path:       string & !=""
	generated:  true
	source:     string & !=""
	projection: string & !=""
	command:    string & !=""
	editable:   false
	validatesWith: [...string & !=""] & [_, ...]
})

#Fixture: close({
	path:           string & !=""
	targetContract: string & !=""
	polarity:       "valid" | "invalid"
	expected:       "pass" | "fail"
	validatesWith:  string & !=""
	reason?:        string & !=""

	if polarity == "valid" {
		expected: "pass"
	}
	if polarity == "invalid" {
		expected: "fail"
	}
})
