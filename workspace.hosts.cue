package workspace

hostWorkspaces: {
	main: #HostWorkspace & {
		id:     "main"
		label:  "primary development host"
		root:   srcRoot
		intent: "Primary local workspace root containing contract, dotfiles, and project sessions."

		surfaces: {
			chezmoi: {
				sourceDir: "\(srcRoot)/dotfiles/chezmoi"
				config:    "\(srcRoot)/dotfiles/chezmoi.toml.tmpl"
			}
			shellWrap: {
				root: "\(srcRoot)/dotfiles/shell-wrap"
			}
			wezterm: {
				configRoot:    "\(srcRoot)/dotfiles/chezmoi/private_dot_config/wezterm"
				workspacesLua: "\(contractRoot)/adapters/wezterm/workspaces.lua"
			}
		}
	}
}
