package agentcontextresolver

#TurnStartFragment: #ProjectedFragment & {
	surface: "turn_start"
}

#TurnStartFragmentSet: {
	generatedFrom: "registry.index.json"
	fragments: [...#TurnStartFragment]
}

turnStartFragmentSet: #TurnStartFragmentSet & {
	generatedFrom: "registry.index.json"
	fragments: [
		for fragment in fragmentInventory.fragments
		if fragment.surface == "turn_start" {
			fragment
		},
	]
}
