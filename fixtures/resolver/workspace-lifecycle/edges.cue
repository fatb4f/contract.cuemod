package workspacelifecycle

import "github.com/fatb4f/contract.cuemod/contracts/context/packet"

graphEdges: [string]: resolver.#Edge
graphEdges: {
	"df:edge/workspace-lifecycle-requires-sessionizer": {
		id:        "df:edge/workspace-lifecycle-requires-sessionizer"
		predicate: "requires"
		source:    "df:contract/workspace-lifecycle"
		target:    "df:node/sessionizer-entrypoint"
	}
	"df:edge/workspace-lifecycle-requires-controller": {
		id:        "df:edge/workspace-lifecycle-requires-controller"
		predicate: "requires"
		source:    "df:contract/workspace-lifecycle"
		target:    "df:node/wezterm-workspace-controller"
	}
	"df:edge/workspace-lifecycle-requires-nvim-client": {
		id:        "df:edge/workspace-lifecycle-requires-nvim-client"
		predicate: "requires"
		source:    "df:contract/workspace-lifecycle"
		target:    "df:node/neovim-workspace-client"
	}
	"df:edge/sessionizer-implemented-by-lua": {
		id:        "df:edge/sessionizer-implemented-by-lua"
		predicate: "implemented_by"
		source:    "df:node/sessionizer-entrypoint"
		target:    "df:implementation/sessionizer-lua"
	}
	"df:edge/controller-implemented-by-launch": {
		id:        "df:edge/controller-implemented-by-launch"
		predicate: "implemented_by"
		source:    "df:node/wezterm-workspace-controller"
		target:    "df:implementation/controller-launch"
	}
	"df:edge/nvim-client-implemented-by-command": {
		id:        "df:edge/nvim-client-implemented-by-command"
		predicate: "implemented_by"
		source:    "df:node/neovim-workspace-client"
		target:    "df:implementation/nvim-client-command"
	}
	"df:edge/sessionizer-stored-in-wezterm": {
		id:        "df:edge/sessionizer-stored-in-wezterm"
		predicate: "stored_in"
		source:    "df:implementation/sessionizer-lua"
		target:    "df:artifact/wezterm-sessionizer-lua"
	}
	"df:edge/controller-stored-in-wezterm": {
		id:        "df:edge/controller-stored-in-wezterm"
		predicate: "stored_in"
		source:    "df:implementation/controller-launch"
		target:    "df:artifact/wezterm-controller-lua"
	}
	"df:edge/nvim-client-stored-in-nvim": {
		id:        "df:edge/nvim-client-stored-in-nvim"
		predicate: "stored_in"
		source:    "df:implementation/nvim-client-command"
		target:    "df:artifact/nvim-workspace-client-lua"
	}
	"df:edge/sessionizer-defines-select-project": {
		id:        "df:edge/sessionizer-defines-select-project"
		predicate: "defines_symbol"
		source:    "df:implementation/sessionizer-lua"
		target:    "df:symbol/sessionizer-select-project"
	}
	"df:edge/controller-defines-launch": {
		id:        "df:edge/controller-defines-launch"
		predicate: "defines_symbol"
		source:    "df:implementation/controller-launch"
		target:    "df:symbol/controller-launch"
	}
	"df:edge/nvim-client-defines-open-workspace": {
		id:        "df:edge/nvim-client-defines-open-workspace"
		predicate: "defines_symbol"
		source:    "df:implementation/nvim-client-command"
		target:    "df:symbol/nvim-client-open-workspace"
	}
	"df:edge/sessionizer-symbol-evidenced": {
		id:        "df:edge/sessionizer-symbol-evidenced"
		predicate: "evidenced_by"
		source:    "df:symbol/sessionizer-select-project"
		target:    "df:evidence/sessionizer-select-project"
	}
	"df:edge/controller-symbol-evidenced": {
		id:        "df:edge/controller-symbol-evidenced"
		predicate: "evidenced_by"
		source:    "df:symbol/controller-launch"
		target:    "df:evidence/controller-launch"
	}
	"df:edge/nvim-client-symbol-evidenced": {
		id:        "df:edge/nvim-client-symbol-evidenced"
		predicate: "evidenced_by"
		source:    "df:symbol/nvim-client-open-workspace"
		target:    "df:evidence/nvim-client-open-workspace"
	}
}
