package workspace

#AbsPath: =~"^/.*$"
#RelPath: string & !~"^/"

#Editor: "nvim" | "helix"

#Language:
	"cue" |
	"lua" |
	"shell" |
	"just" |
	"go" |
	"typescript" |
	"javascript" |
	"python" |
	"rust" |
	"zig" |
	"markdown" |
	"json" |
	"yaml" |
	"toml"

#TaskName:
	"default" |
	"launch-workspace" |
	"send-to-editor" |
	"send-to-nvim" |
	"build" |
	"test" |
	"lint" |
	"check" |
	"fmt" |
	"doctor" |
	string

#CommandSpec: {
	name: #TaskName
	argv: [...string]
	cwd?: #AbsPath
	env?: [string]: string
	palette?:     bool | *true
	oneshot?:     bool | *true
	description?: string
}

#LintBackend: "pre-commit" | "shell-wrap" | "direct"

#PreCommitLint: {
	backend:    "pre-commit"
	configPath: #RelPath | *".pre-commit-config.yaml"
	allFiles:   bool | *true
	command: #CommandSpec | *{
		name: "lint"
		argv: ["pre-commit", "run", "--all-files"]
		palette: true
		oneshot: true
	}
}

#DirectLint: {
	backend: "direct" | "shell-wrap"
	steps: [...#LintStep]
	aggregate: #CommandSpec | *{
		name: "lint"
		argv: ["shell-wrap", "lint"]
		palette: true
		oneshot: true
	}
}

#LintPolicy: #PreCommitLint | #DirectLint

#LintStep: {
	id:       =~"^[a-z0-9][a-z0-9._-]*$"
	language: #Language
	tool:     string
	command:  #CommandSpec
}

#ToolchainProfile: {
	languages: [...#Language]
	lint?: #LintPolicy
	fmt?: {
		backend: "pre-commit" | "shell-wrap" | "direct"
		steps?: [...#LintStep]
		aggregate?: #CommandSpec
	}
	test?:  #CommandSpec
	build?: #CommandSpec
}

#HostWorkspace: {
	id:     =~"^[a-z0-9][a-z0-9._-]*$"
	label:  string
	root:   #AbsPath
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
}

#ProjectSession: {
	id:     =~"^[a-z0-9][a-z0-9._-]*$"
	label:  string
	root:   #AbsPath
	kind:   "contract" | "dotfiles" | "learning" | "project"
	intent: string
	editor: #Editor | *"nvim"

	toolchain?: #ToolchainProfile

	commands: {
		default?: string
		check?:   string
		test?:    string
		build?:   string
		lint?:    string
		fmt?:     string
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
		shellWrap?: {
			cwd: #AbsPath | *root
			commands?: {
				lint?:  #CommandSpec
				fmt?:   #CommandSpec
				check?: #CommandSpec
				test?:  #CommandSpec
				build?: #CommandSpec
			}
		}
	}
}

#Domain: {
	name:         string
	kind:         "workspace" | "materializer" | "adapter" | "config" | "shell"
	root:         #AbsPath
	relativeRoot: #RelPath | *"."
	router?:      #RelPath
	surfaces: [...#RelPath]
	owns: [...string]
	denies?: [...string]
	validations?: [...string]
	closeout?: [...string]
}

#WorkflowPolicy: {
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
		owner:              "wezterm"
		primitive:          "focus-pane"
		scope:              "terminal-panes-and-editor-surface"
		editorGlueRequired: false
		notes: [...string]
	}
}

#HostsProjection: {
	version:         "workspace.hosts.v1"
	contractVersion: string
	srcRoot:         #AbsPath
	contractRoot:    #AbsPath
	hosts: [...#HostWorkspace]
}

#ProjectsProjection: {
	version:         "workspace.projects.v1"
	contractVersion: string
	srcRoot:         #AbsPath
	contractRoot:    #AbsPath
	projects: [...#ProjectSession]
}

#DomainsProjection: {
	version:         "workspace.domains.v1"
	contractVersion: string
	srcRoot:         #AbsPath
	contractRoot:    #AbsPath
	domains: [...#Domain]
}

#WorkflowProjection: {
	version:         "workspace.workflow.v1"
	contractVersion: string
	srcRoot:         #AbsPath
	contractRoot:    #AbsPath
	workflow:        #WorkflowPolicy
}

#ContractProjection: {
	version:         "workspace.contract.v1"
	contractVersion: string
	srcRoot:         #AbsPath
	contractRoot:    #AbsPath
	hosts: [...#HostWorkspace]
	projects: [...#ProjectSession]
	domains: [...#Domain]
	workflow: #WorkflowPolicy
}
