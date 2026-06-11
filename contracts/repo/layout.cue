package repo

#RepoLayout: close({
	module: string & !=""
	surfaces: [...#RepoSurface] & [_, ...]
	assets: [...#RepoAsset] & [_, ...]
	fixtures: [...#Fixture]
	generatedAssets: [...#GeneratedAsset]
})
