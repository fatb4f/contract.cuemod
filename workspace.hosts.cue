package workspace

hostWorkspaces: {
	dotfiles: #HostWorkspace & {
		id:     "dotfiles"
		label:  "dotfiles host workspace"
		root:   "\(srcRoot)/dotfiles"
		intent: "Host control-plane implementation repo. It materializes configuration through chezmoi and exposes shell/terminal/editor adapters, but it does not own the global workspace contract."

		surfaces: {
			chezmoi: {
				sourceDir: "\(root)/chezmoi"
				config:    "\(root)/chezmoi.toml.tmpl"
			}

			shellWrap: {
				root: "\(root)/shell-wrap"
			}

			wezterm: {
				configRoot:    "\(root)/chezmoi/private_dot_config/wezterm"
				workspacesLua: "\(configRoot)/modules/workspaces.lua"
			}
		}

		domains: dotfilesDomains
	}
}
