package agentskill

#ContractID:   string & =~"^df:contract/[a-z0-9._-]+$"
#ProjectionID: string & =~"^df:projection/[a-z0-9._-]+$"

#SkillName: string & =~"^[a-z0-9]+(?:-[a-z0-9]+)*$"

#RelativePath: string & !="" & !~"^/" & !~"(^|/)\\.\\.(/|$)"

#ProjectionProvenance: close({
	projection_id: #ProjectionID
	contract_ids: [#ContractID, ...#ContractID]
	generated: true
})

#SkillMetadata: close({
	name:        #SkillName
	description: string & !=""
	path:        ".codex/skills/\(name)/SKILL.md"
	provenance:  #ProjectionProvenance
})

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

#ScriptAsset: close({
	path:       #RelativePath & =~"^\\.codex/skills/[a-z0-9-]+/scripts/[a-z0-9-]+$" & !~"(^|/)bin/"
	content:    string & =~"^#!/bin/sh\n" & !~"/home/_404/src/contract\\.cuemod" & !~"/[^ \t\n]*/dotfiles/bin"
	executable: true
	provenance: #ProjectionProvenance
})

#SkillProjection: close({
	metadata: #SkillMetadata
	hooks:    #HookProjection
	scripts: [string]: #ScriptAsset
})
