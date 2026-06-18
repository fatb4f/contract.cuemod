package invaliddirect

import "github.com/fatb4f/contract.cuemod/contracts/graph"

artifact: graph.#ArtifactAccess & {
	artifact_id: "df:artifact/wezterm-smart-splits-lua"
	access: {
		direct: true
		providers: ["df:provider/lua-lsp-mcp"]
	}
}
