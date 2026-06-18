package valid

import "github.com/fatb4f/contract.cuemod/contracts/graph"

artifact: graph.#ArtifactAccess & {
	artifact_id: "df:artifact/wezterm-smart-splits-lua"
	raw_path:    "chezmoi/private_dot_config/wezterm/modules/smart_splits.lua"
	access: {
		direct: false
		providers: [
			"df:provider/lua-lsp-mcp",
		]
	}
}
