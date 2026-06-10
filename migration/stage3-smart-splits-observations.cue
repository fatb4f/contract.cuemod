package migration

// Observations retained for migration only. They do not define authority.
stage3SmartSplitsObservations: {
	terms: [
		"smart-splits",
		"smart_splits",
		"IS_NVIM",
	]
	artifacts: [
		{
			artifact_id: "df:artifact/wezterm-smart-splits-lua"
			raw_path:    "chezmoi/private_dot_config/wezterm/modules/smart_splits.lua"
		},
		{
			artifact_id: "df:artifact/nvim-smart-splits-config"
			raw_path:    "chezmoi/private_dot_config/nvim/lua/workflow/smart_splits.lua"
		},
	]
	symbols: [
		"smart_splits.apply_to_config",
		"smart_splits.setup",
	]
	projectionIntents: [
		"cross-tool-pane-navigation",
		"treat-terminal-and-editor-implementations-as-distinct",
	]
}
