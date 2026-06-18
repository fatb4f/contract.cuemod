package assertions

import factory "github.com/fatb4f/contract.reflective-transition-factory/contracts/factory"

#AllowedRootSurfaces: [
	".github",
	"contracts",
	"migration",
	"cmd",
	"internal",
	"go.mod",
	"justfile",
	"README.md",
]

#ForbiddenIndependentRoots: [
	"fixtures",
	"generated",
	"providers",
	"projections",
	"adapters",
	"test",
]

factoryPruningGate: {
	surface: factory.surface
	invariant: "top-level fixtures and generated outputs are factory fixtures, factory projections, or migration evidence"
	allowedRootSurfaces: #AllowedRootSurfaces
	forbiddenIndependentRoots: #ForbiddenIndependentRoots
}
