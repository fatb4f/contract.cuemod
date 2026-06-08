package workspace

dotfilesDomains: {
	contract: #Domain & {
		name: "contract"
		kind: "workspace"
		root: contractRoot
		relativeRoot: "."
		router: "README.md"
		surfaces: [
			"workspace.cue",
			"workspace.schema.cue",
			"workspace.hosts.cue",
			"workspace.projects.cue",
			"workspace.domains.cue",
			"workspace.workflow.cue",
			"workspace.projections.cue",
			"workspace_tool.cue",
			"workspace.*.json",
		]
		owns: [
			"workspace contract authority",
			"project session declarations",
			"adapter-neutral projections",
			"zero-drift terminal workflow policy",
		]
		denies: [
			"runtime pane registry",
			"adapter-owned manifest",
			"orchestration daemon",
			"runtime project discovery",
		]
		validations: [
			"cue cmd export",
			"cue cmd validate",
			"cue cmd check",
		]
		closeout: [
			"cue projections regenerated",
			"generated JSON freshness checked",
			"adapter boundaries preserved",
		]
	}

	dotfiles: #Domain & {
		name: "dotfiles"
		kind: "workspace"
		root: "\(srcRoot)/dotfiles"
		relativeRoot: "dotfiles"
		surfaces: [
			"chezmoi/**",
			"shell-wrap/**",
			"justfile",
		]
		owns: [
			"dotfiles implementation",
			"chezmoi materialization",
			"shell-wrap adapter source",
		]
		denies: [
			"workspace contract authority",
			"runtime pane registry",
		]
	}

	wezterm: #Domain & {
		name: "wezterm"
		kind: "config"
		root: "\(srcRoot)/dotfiles/chezmoi/private_dot_config/wezterm"
		relativeRoot: "dotfiles/chezmoi/private_dot_config/wezterm"
		surfaces: ["**"]
		owns: [
			"terminal panes",
			"workspace surface",
			"focus-pane movement",
			"single just palette bind",
		]
		denies: [
			"recipe definitions",
			"lint toolchain inference",
			"editor buffer ownership",
		]
	}

	xplr: #Domain & {
		name: "xplr"
		kind: "config"
		root: "\(srcRoot)/dotfiles/chezmoi/private_dot_config/xplr"
		relativeRoot: "dotfiles/chezmoi/private_dot_config/xplr"
		surfaces: ["**"]
		owns: [
			"focused path",
			"selection",
			"send focused path to editor recipe",
		]
		denies: [
			"command orchestration",
			"pane management",
			"lint toolchain inference",
		]
	}

	nvim: #Domain & {
		name: "nvim"
		kind: "config"
		root: "\(srcRoot)/dotfiles/chezmoi/private_dot_config/nvim"
		relativeRoot: "dotfiles/chezmoi/private_dot_config/nvim"
		surfaces: ["**"]
		owns: [
			"editing state",
			"buffers",
			"language services",
		]
		denies: [
			"process surface ownership",
			"pane routing",
			"task-runner plugin authority",
		]
	}

	shellWrap: #Domain & {
		name: "shell-wrap"
		kind: "adapter"
		root: "\(srcRoot)/dotfiles/shell-wrap"
		relativeRoot: "dotfiles/shell-wrap"
		surfaces: ["**"]
		owns: [
			"generated shell adapters",
			"declared command execution",
			"lint/fmt/check adapter projection",
		]
		denies: [
			"runtime language discovery",
			"workspace membership authority",
		]
	}
}
