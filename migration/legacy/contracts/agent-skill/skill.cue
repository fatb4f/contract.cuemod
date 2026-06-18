package agentskill

import "github.com/fatb4f/contract.cuemod/contracts/graph"

#SkillName: string & =~"^[a-z0-9]+(?:-[a-z0-9]+)*$"

#RelativePath: string & !="" & !~"^/" & !~"(^|/)\\.\\.(/|$)"

#ProjectionProvenance: close({
	projection_id: graph.#ProjectionID
	contract_ids: [graph.#ContractID, ...graph.#ContractID]
	generated: true
})

#SkillMetadata: close({
	name:        #SkillName
	description: string & !=""
	path:        ".codex/skills/\(name)/SKILL.md"
	provenance:  #ProjectionProvenance
})

#SkillProjection: close({
	metadata: #SkillMetadata
	hooks:    #HookProjection
	scripts: [string]: #ScriptAsset
})
