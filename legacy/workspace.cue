package workspace

#Workspace: {
	name:        string
	root:        string
	chezmoiRoot: string
	registries: {
		domains: [string]: #Domain
		skills?: [string]: #Skill
	}
}

#Domain: {
	name:    string
	kind:    "workspace" | "materializer" | "adapter" | "config" | "shell"
	root:    string
	router?: string
	surfaces: [...string]
	owns: [...string]
	denies?: [...string]
	validations?: [...string]
	closeout?: [...string]
}

#Skill: {
	name: string
	path: string
	tasks: [...string]
}

workspace: #Workspace & {
	name:        "dotfiles"
	root:        "."
	chezmoiRoot: "chezmoi"

	registries: {
		domains: domains
		skills:  skills
	}
}

domains: {
	dotfiles: #Domain & {
		name:   "dotfiles"
		kind:   "workspace"
		root:   "."
		router: ".codex/skills/SKILL.md"
		surfaces: [
			".chezmoiroot",
			".gitignore",
			"chezmoi.toml.tmpl",
			"workspace.cue",
		]
		owns: [
			"workspace registry",
			"repository routing",
			"domain selection",
			"cross-domain handoff",
		]
		denies: [
			"tool cache state",
			"runtime state",
			"git object storage",
		]
		validations: [
			"cue vet workspace.cue",
			"cue eval workspace.cue",
		]
		closeout: [
			"selected domain",
			"loaded files",
			"changed files",
			"validation evidence",
		]
	}

	chezmoi: #Domain & {
		name: "chezmoi"
		kind: "materializer"
		root: "chezmoi"
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
		]
		validations: [
			"chezmoi status",
			"chezmoi diff",
		]
		closeout: [
			"source paths changed",
			"target impact summary",
			"apply preview status",
		]
	}

	agent_skills: #Domain & {
		name: "agent-skills"
		kind: "config"
		root: "chezmoi/dot_local/share/codex/skills"
		surfaces: [
			"chezmoi/dot_local/share/codex/skills/**",
		]
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

	hypr: #Domain & {
		name: "hypr"
		kind: "config"
		root: "chezmoi/private_dot_config/hypr"
		surfaces: [
			"chezmoi/private_dot_config/hypr/**",
		]
		owns: [
			"Hyprland Lua configuration",
			"Hyprland module files",
			"hypridle configuration",
			"hyprlock configuration",
			"hyprpaper configuration",
		]
		validations: [
			"lua syntax check when available",
			"hyprctl reload when explicitly requested",
		]
	}

	nvim: #Domain & {
		name: "nvim"
		kind: "config"
		root: "chezmoi/private_dot_config/nvim"
		surfaces: [
			"chezmoi/private_dot_config/nvim/**",
		]
		owns: [
			"Neovim Lua configuration",
			"Neovim plugin specs",
			"Neovim keymaps",
			"Neovim options",
		]
		validations: [
			"lua syntax check when available",
			"nvim headless check when explicitly requested",
		]
	}

	wezterm: #Domain & {
		name: "wezterm"
		kind: "config"
		root: "chezmoi/private_dot_config/wezterm"
		surfaces: [
			"chezmoi/private_dot_config/wezterm/**",
		]
		owns: [
			"WezTerm Lua configuration",
			"WezTerm module files",
			"terminal topology",
			"pane and workspace bindings",
		]
		denies: [
			"xplr state",
			"shell-wrap generated commands",
		]
		validations: [
			"lua syntax check when available",
			"wezterm cli check when available",
		]
	}

	xplr: #Domain & {
		name: "xplr"
		kind: "config"
		root: "chezmoi/private_dot_config/xplr"
		surfaces: [
			"chezmoi/private_dot_config/xplr/**",
		]
		owns: [
			"xplr configuration",
			"xplr keybindings",
			"xplr modes",
			"filesystem session state policy",
		]
		denies: [
			"WezTerm pane topology",
			"shell-wrap generated commands",
		]
		validations: [
			"lua syntax check when available",
		]
	}

	zsh: #Domain & {
		name: "zsh"
		kind: "shell"
		root: "chezmoi/private_dot_config/zsh"
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
		validations: [
			"zsh -n when available",
		]
	}

	local_bin: #Domain & {
		name: "local-bin"
		kind: "config"
		root: "chezmoi/dot_local/bin"
		surfaces: [
			"chezmoi/dot_local/bin/**",
		]
		owns: [
			"managed local executable links",
			"chezmoi local-bin projections",
		]
		validations: [
			"template review",
		]
	}

	shell_wrap: #Domain & {
		name:   "shell-wrap"
		kind:   "adapter"
		root:   "shell-wrap"
		router: "shell-wrap/AGENTS.md"
		surfaces: [
			"shell-wrap/**",
		]
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
		closeout: [
			"source scripts changed",
			"generated executable status",
			"test evidence",
		]
	}

	session: #Domain & {
		name:   "session"
		kind:   "adapter"
		root:   "shell-wrap/src/session"
		router: "shell-wrap/AGENTS.md"
		surfaces: [
			"shell-wrap/src/session/**",
			"shell-wrap/tests/session_*.bats",
			"shell-wrap/scripts/verify-tomat-break-flow",
		]
		owns: [
			"session Bashly project",
			"session command source",
			"session generated executable",
			"session system artifacts",
			"session bats tests",
		]
		validations: [
			"bashly generate",
			"bats shell-wrap/tests/session_*.bats",
		]
	}
}

skills: {
	dotfiles: #Skill & {
		name: "dotfiles"
		path: ".codex/skills/SKILL.md"
		tasks: [
			"dotfiles.discovery",
			"dotfiles.registry",
			"dotfiles.route",
			"dotfiles.edit-registry",
			"dotfiles.closeout",
		]
	}
}
