package workspace

dotfilesDomains: {
	dotfiles: #Domain & {
		name:         "dotfiles"
		kind:         "workspace"
		root:         "\(srcRoot)/dotfiles"
		relativeRoot: "."
		router:       ".codex/skills/SKILL.md"
		surfaces: [
			".chezmoiroot",
			".gitignore",
			"chezmoi.toml.tmpl",
		]
		owns: [
			"repository routing",
			"domain selection",
			"cross-domain handoff",
		]
		denies: [
			"tool cache state",
			"runtime state",
			"git object storage",
			"global workspace contract authority",
		]
		validations: [
			"chezmoi diff",
			"git status --short",
		]
		closeout: [
			"selected domain",
			"loaded files",
			"changed files",
			"validation evidence",
		]
	}

	chezmoi: #Domain & {
		name:         "chezmoi"
		kind:         "materializer"
		root:         "\(srcRoot)/dotfiles/chezmoi"
		relativeRoot: "chezmoi"
		surfaces: [
			"chezmoi/.chezmoiignore",
			"chezmoi/dot_*",
			"chezmoi/private_dot_config/**",
			"chezmoi/dot_local/**",
		]
		owns: [
			"chezmoi source files",
			"source-to-target mapping",
			"template source files",
			"ignore policy",
		]
		denies: [
			"sibling workspace domains",
			"git object storage",
			"tool runtime caches",
			"project-session authority",
		]
		validations: [
			"chezmoi status",
			"chezmoi diff",
		]
	}

	shellWrap: #Domain & {
		name:         "shell-wrap"
		kind:         "adapter"
		root:         "\(srcRoot)/dotfiles/shell-wrap"
		relativeRoot: "shell-wrap"
		router:       "shell-wrap/AGENTS.md"
		surfaces: ["shell-wrap/**"]
		owns: [
			"Bashly source projects",
			"shell adapter source",
			"shell adapter tests",
			"system integration artifacts under shell-wrap",
		]
		denies: [
			"chezmoi source-to-target materialization",
			"workspace registry authority",
		]
		validations: [
			"shellharden",
			"shfmt",
			"shellcheck",
			"bashly generate",
			"bats tests",
		]
	}

	wezterm: #Domain & {
		name:         "wezterm"
		kind:         "config"
		root:         "\(srcRoot)/dotfiles/chezmoi/private_dot_config/wezterm"
		relativeRoot: "chezmoi/private_dot_config/wezterm"
		surfaces: ["chezmoi/private_dot_config/wezterm/**"]
		owns: [
			"WezTerm Lua configuration",
			"WezTerm module files",
			"terminal topology",
			"pane and workspace bindings",
		]
		denies: [
			"project-session authority",
			"runtime project discovery",
			"persistent pane registry",
		]
		validations: [
			"lua syntax check when available",
			"wezterm cli check when available",
		]
	}

	nvim: #Domain & {
		name:         "nvim"
		kind:         "config"
		root:         "\(srcRoot)/dotfiles/chezmoi/private_dot_config/nvim"
		relativeRoot: "chezmoi/private_dot_config/nvim"
		surfaces: ["chezmoi/private_dot_config/nvim/**"]
		owns: [
			"Neovim Lua configuration",
			"Neovim keymaps",
			"Neovim options",
			"editor adapter configuration",
		]
		denies: [
			"terminal pane registry",
			"project-session authority",
		]
		validations: [
			"lua syntax check when available",
			"nvim headless check when explicitly requested",
		]
	}

	xplr: #Domain & {
		name:         "xplr"
		kind:         "config"
		root:         "\(srcRoot)/dotfiles/chezmoi/private_dot_config/xplr"
		relativeRoot: "chezmoi/private_dot_config/xplr"
		surfaces: ["chezmoi/private_dot_config/xplr/**"]
		owns: [
			"xplr configuration",
			"xplr keybindings",
			"focused file selection",
		]
		denies: [
			"WezTerm pane topology",
			"command catalog authority",
			"project-session authority",
		]
		validations: ["lua syntax check when available"]
	}

	zsh: #Domain & {
		name:         "zsh"
		kind:         "shell"
		root:         "\(srcRoot)/dotfiles/chezmoi/private_dot_config/zsh"
		relativeRoot: "chezmoi/private_dot_config/zsh"
		surfaces: [
			"chezmoi/dot_zprofile",
			"chezmoi/dot_zshenv",
			"chezmoi/private_dot_config/zsh/**",
		]
		owns: [
			"zsh startup files",
			"zsh loader files",
			"zsh functions",
			"zim configuration",
		]
		validations: ["zsh -n when available"]
	}

	localBin: #Domain & {
		name:         "local-bin"
		kind:         "config"
		root:         "\(srcRoot)/dotfiles/chezmoi/dot_local/bin"
		relativeRoot: "chezmoi/dot_local/bin"
		surfaces: ["chezmoi/dot_local/bin/**"]
		owns: [
			"managed local executable links",
			"chezmoi local-bin projections",
		]
		validations: ["template review"]
	}

	agentSkills: #Domain & {
		name:         "agent-skills"
		kind:         "config"
		root:         "\(srcRoot)/dotfiles/chezmoi/dot_local/share/codex/skills"
		relativeRoot: "chezmoi/dot_local/share/codex/skills"
		surfaces: ["chezmoi/dot_local/share/codex/skills/**"]
		owns: [
			"agent skill markdown",
			"skill routing instructions",
			"task procedure contracts",
		]
		denies: [
			"codex auth state",
			"codex cache state",
			"codex tmp state",
		]
		validations: [
			"markdown review",
			"path registry review",
		]
	}
}
