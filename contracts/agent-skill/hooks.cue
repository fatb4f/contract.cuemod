package agentskill

#HookCommand: close({
	type:          "command"
	command:       #RelativePath & =~"^\\.codex/skills/[a-z0-9-]+/scripts/[a-z0-9-]+$"
	timeout:       int & >0
	statusMessage: string & !=""
})

#HookProjection: close({
	hooks: {
		UserPromptSubmit: [{
			hooks: [#HookCommand, ...#HookCommand]
		}]
	}
})
