package workspace

projectSessions: {
	contract: #ProjectSession & {
		id:     "contract"
		label:  "workspace contract"
		root:   contractRoot
		kind:   "contract"
		intent: "Global workspace contract authority. Declares host workspaces, project sessions, workflow policy, and generated adapter-neutral projections."
		editor: "nvim"

		toolchain: {
			languages: ["cue", "just", "shell"]
			lint: {
				backend: "direct"
				steps: [
					{
						id:       "cue-vet"
						language: "cue"
						tool:     "cue"
						command: {
							name: "lint"
							argv: ["cue", "vet", "."]
							cwd: root
						}
					},
					{
						id:       "cue-export-check"
						language: "cue"
						tool:     "cue"
						command: {
							name: "check"
							argv: ["cue", "cmd", "check"]
							cwd: root
						}
					},
				]
				aggregate: {
					name: "lint"
					argv: ["cue", "cmd", "validate"]
					cwd: root
				}
			}
		}

		commands: {
			default: "just --choose"
			check:   "cue cmd check"
			build:   "cue cmd export"
			lint:    "cue cmd validate"
			fmt:     "cue fmt ."
		}
	}

	dotfiles: #ProjectSession & {
		id:     "dotfiles"
		label:  "dotfiles"
		root:   "\(srcRoot)/dotfiles"
		kind:   "dotfiles"
		intent: "Open the dotfiles implementation repo as an editable project context."
		editor: "nvim"

		toolchain: {
			languages: ["lua", "shell", "cue", "just", "yaml"]
			// Preferred for multi-language dotfiles: let pre-commit own hook wiring,
			// while just/shell-wrap expose the stable lint verb.
			lint: {
				backend:    "pre-commit"
				configPath: ".pre-commit-config.yaml"
				allFiles:   true
				command: {
					name: "lint"
					argv: ["pre-commit", "run", "--all-files"]
					cwd:     root
					palette: true
					oneshot: true
				}
			}
		}

		commands: {
			default: "just --choose"
			check:   "just lint"
			lint:    "shell-wrap lint"
			fmt:     "shell-wrap fmt"
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

		toolchain: {
			languages: ["shell", "markdown", "just"]
			lint: {
				backend: "shell-wrap"
				steps: [
					{
						id:       "shellcheck"
						language: "shell"
						tool:     "shellcheck"
						command: {
							name: "lint"
							argv: ["shellcheck", "-x", "exercises/**/*.sh"]
							cwd: root
						}
					},
					{
						id:       "markdownlint"
						language: "markdown"
						tool:     "markdownlint"
						command: {
							name: "lint"
							argv: ["markdownlint", "."]
							cwd: root
						}
					},
				]
				aggregate: {
					name: "lint"
					argv: ["shell-wrap", "lint"]
					cwd: root
				}
			}
		}

		commands: {
			default: "just --choose"
			check:   "just lint"
			lint:    "shell-wrap lint"
			open:    "nvim"
		}
	}
}

// Default adapter projections for every project. These are deterministic
// projections; they are not runtime discovery results.
projectSessions: [Name=string]: {
	let projectID = projectSessions[Name].id
	let projectRoot = projectSessions[Name].root
	let projectEditor = projectSessions[Name].editor

	adapters: {
		wezterm: {
			workspace: projectID
			cwd:       projectRoot
		}
		editor: {
			command: projectEditor
			cwd:     projectRoot
		}
		xplr: {
			cwd: projectRoot
		}
		just: {
			cwd: projectRoot
		}
		shell: {
			cwd: projectRoot
		}
		shellWrap: {
			cwd: projectRoot
			commands: {
				lint: {
					name: "lint"
					argv: ["shell-wrap", "lint"]
					cwd: projectRoot
				}
				fmt: {
					name: "fmt"
					argv: ["shell-wrap", "fmt"]
					cwd: projectRoot
				}
				check: {
					name: "check"
					argv: ["shell-wrap", "check"]
					cwd: projectRoot
				}
			}
		}
	}
}
