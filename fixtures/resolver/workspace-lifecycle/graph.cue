package workspacelifecycle

import "github.com/fatb4f/contract.cuemod/contracts/context/packet"

entities: {
	"df:contract/workspace-lifecycle": {
		id:   "df:contract/workspace-lifecycle"
		kind: "contract"
		name: "workspace lifecycle capability"
	}
	"df:node/sessionizer-entrypoint": {
		id:   "df:node/sessionizer-entrypoint"
		kind: "node"
		name: "sessionizer entrypoint"
	}
	"df:node/wezterm-workspace-controller": {
		id:   "df:node/wezterm-workspace-controller"
		kind: "node"
		name: "WezTerm workspace controller"
	}
	"df:node/neovim-workspace-client": {
		id:   "df:node/neovim-workspace-client"
		kind: "node"
		name: "Neovim workspace client"
	}
	"df:implementation/sessionizer-lua": {
		id:   "df:implementation/sessionizer-lua"
		kind: "implementation"
		name: "sessionizer Lua implementation"
	}
	"df:implementation/controller-launch": {
		id:   "df:implementation/controller-launch"
		kind: "implementation"
		name: "controller launch implementation"
	}
	"df:implementation/nvim-client-command": {
		id:   "df:implementation/nvim-client-command"
		kind: "implementation"
		name: "Neovim client command implementation"
	}
	"df:artifact/wezterm-sessionizer-lua": {
		id:       "df:artifact/wezterm-sessionizer-lua"
		kind:     "artifact"
		name:     "WezTerm sessionizer Lua"
		raw_path: "chezmoi/private_dot_config/wezterm/sessionizer.lua"
	}
	"df:artifact/wezterm-controller-lua": {
		id:       "df:artifact/wezterm-controller-lua"
		kind:     "artifact"
		name:     "WezTerm controller Lua"
		raw_path: "chezmoi/private_dot_config/wezterm/controller.lua"
	}
	"df:artifact/nvim-workspace-client-lua": {
		id:       "df:artifact/nvim-workspace-client-lua"
		kind:     "artifact"
		name:     "Neovim workspace client Lua"
		raw_path: "chezmoi/private_dot_config/nvim/lua/workspace/client.lua"
	}
	"df:artifact/xplr-workspace-lua": {
		id:   "df:artifact/xplr-workspace-lua"
		kind: "artifact"
		name: "xplr workspace Lua"
	}
	"df:artifact/nvim-unrelated-config": {
		id:   "df:artifact/nvim-unrelated-config"
		kind: "artifact"
		name: "unrelated Neovim config"
	}
	"df:symbol/sessionizer-select-project": {
		id:     "df:symbol/sessionizer-select-project"
		kind:   "symbol"
		name:   "sessionizer.select_project"
		symbol: "sessionizer.select_project"
	}
	"df:symbol/controller-launch": {
		id:     "df:symbol/controller-launch"
		kind:   "symbol"
		name:   "controller.launch"
		symbol: "controller.launch"
	}
	"df:symbol/nvim-client-open-workspace": {
		id:     "df:symbol/nvim-client-open-workspace"
		kind:   "symbol"
		name:   "nvim_client.open_workspace"
		symbol: "nvim_client.open_workspace"
	}
	"df:evidence/sessionizer-select-project": {
		id:          "df:evidence/sessionizer-select-project"
		kind:        "evidence"
		name:        "sessionizer.select_project definition range"
		raw_path:    "chezmoi/private_dot_config/wezterm/sessionizer.lua"
		symbol:      "sessionizer.select_project"
		provider_id: "df:provider/lua-lsp-mcp"
		range: {
			start: {line: 41, character: 1}
			end: {line: 63, character: 4}
		}
	}
	"df:evidence/controller-launch": {
		id:          "df:evidence/controller-launch"
		kind:        "evidence"
		name:        "controller.launch definition range"
		raw_path:    "chezmoi/private_dot_config/wezterm/controller.lua"
		symbol:      "controller.launch"
		provider_id: "df:provider/lua-lsp-mcp"
		range: {
			start: {line: 18, character: 1}
			end: {line: 37, character: 4}
		}
	}
	"df:evidence/nvim-client-open-workspace": {
		id:          "df:evidence/nvim-client-open-workspace"
		kind:        "evidence"
		name:        "nvim_client.open_workspace definition range"
		raw_path:    "chezmoi/private_dot_config/nvim/lua/workspace/client.lua"
		symbol:      "nvim_client.open_workspace"
		provider_id: "df:provider/lua-lsp-mcp"
		range: {
			start: {line: 12, character: 1}
			end: {line: 29, character: 4}
		}
	}
}

validatedEntities: [for _, entity in entities {
	resolver.#Entity & entity
}]
