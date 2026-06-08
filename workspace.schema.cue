package workspace

#AbsPath: =~"^/.*$"
#RelPath: string

#AdapterName: "wezterm" | "editor" | "xplr" | "just" | "shell" | "chezmoi"

#HostWorkspace: {
	id:    =~"^[a-z0-9][a-z0-9._-]*$"
	label: string
	root:  #AbsPath

	intent: string

	surfaces: {
		chezmoi?: {
			sourceDir: #AbsPath
			config:    #AbsPath
		}

		shellWrap?: {
			root: #AbsPath
		}

		wezterm?: {
			configRoot:    #AbsPath
			workspacesLua: #AbsPath
		}
	}

	domains?: [string]: #Domain
}

#ProjectSession: {
	id:    =~"^[a-z0-9][a-z0-9._-]*$"
	label: string
	root:  #AbsPath
	kind:  "contract" | "dotfiles" | "learning" | "project"

	intent: string

	editor: "nvim" | "helix" | *"nvim"

	commands: {
		default?: string
		check?:   string
		test?:    string
		build?:   string
		open?:    string
	}

	env: {
		TERM_PROJECT_ID:   id
		TERM_PROJECT_ROOT: root
		TERM_EDITOR:       editor
	}

	adapters: {
		wezterm?: {
			workspace: string | *id
			cwd:       #AbsPath | *root
		}

		editor?: {
			command: string | *editor
			cwd:     #AbsPath | *root
		}

		xplr?: {
			cwd: #AbsPath | *root
		}

		just?: {
			cwd: #AbsPath | *root
		}

		shell?: {
			cwd: #AbsPath | *root
		}
	}
}

#Domain: {
	name:    string
	kind:    "workspace" | "materializer" | "adapter" | "config" | "shell"
	root:    #AbsPath
	relativeRoot: #RelPath
	router?: #RelPath
	surfaces: [...#RelPath]
	owns: [...string]
	denies?: [...string]
	validations?: [...string]
	closeout?: [...string]
}

#WorkflowPolicy: {
	name: string
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
		notes: [...string]
	}
}
