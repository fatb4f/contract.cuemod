package workspace

workflowPolicy: #WorkflowPolicy & {
	name: "zero-drift-terminal-workspace"

	statePolicy: {
		runtimeDiscovery:     false
		paneRegistry:         false
		orchestrationDaemon:  false
		crossVmIpc:           false
		adapterOwnedManifest: false
	}

	commandContract: {
		owner:  "just"
		source: "justfile"
	}

	palettePolicy: {
		singlePaletteBind: true
		recipeChooser:     "fzf"
		recipeSource:      "just --choose"
	}

	movementPolicy: {
		owner: "wezterm"
		scope: "terminal-panes-and-editor-surface"
		notes: [
			"Focus-pane at the terminal layer removes the need for editor-specific pane movement glue.",
			"Neovim and Helix remain editor surfaces, not pane routers.",
		]
	}
}
