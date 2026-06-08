package workspace

projectSessions: {
	contract: #ProjectSession & {
		id:     "contract"
		label:  "workspace contract"
		root:   contractRoot
		kind:   "contract"
		intent: "Global workspace contract authority. Declares host workspaces, project sessions, workflow policy, and generated adapter-neutral projections."
		editor: "nvim"

		commands: {
			default: "just --choose"
			check:   "cue vet . && python3 scripts/validate_json.py"
			build:   "just export"
		}
	}

	dotfiles: #ProjectSession & {
		id:     "dotfiles"
		label:  "dotfiles"
		root:   "\(srcRoot)/dotfiles"
		kind:   "dotfiles"
		intent: "Open the dotfiles implementation repo as an editable project context. Distinct from its host-workspace role."
		editor: "nvim"

		commands: {
			default: "just --choose"
			check:   "chezmoi diff"
			open:    "nvim"
		}
	}

	gitKatasProgit: #ProjectSession & {
		id:     "git-katas-progit"
		label:  "git-katas-progit"
		root:   "\(srcRoot)/git-katas-progit"
		kind:   "learning"
		intent: "Open the Pro Git aligned git-katas learning project."
		editor: "nvim"

		commands: {
			default: "just --choose"
			check:   "just check"
			open:    "nvim"
		}
	}
}

projectSessions: [Name=string]: adapters: {
	wezterm: {
		workspace: id
		cwd:       root
	}

	editor: {
		command: editor
		cwd:     root
	}

	xplr: {
		cwd: root
	}

	just: {
		cwd: root
	}

	shell: {
		cwd: root
	}
}
