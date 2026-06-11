package repo

inventory: [
	for surface in manifest.surfaces {
		path:          surface.path
		kind:          surface.kind
		role:          surface.role
		lifecycle:     surface.lifecycle
		authority:     surface.authority
		generated:     surface.generated
		owner:         surface.owner
		validatesWith: surface.validatesWith
		status:        "declared" | "legacy" | "generated"
		if surface.lifecycle == "deprecated" {
			status: "legacy"
		}
		if surface.generated {
			status: "generated"
		}
		if surface.lifecycle != "deprecated" && !surface.generated {
			status: "declared"
		}
	},
	for asset in manifest.assets {
		path:          asset.path
		kind:          asset.kind
		role:          asset.role
		lifecycle:     asset.lifecycle
		authority:     asset.authority
		generated:     asset.generated
		owner:         asset.owner
		validatesWith: asset.validatesWith
		status:        "declared"
	},
]
