package agentskill

#ScriptAsset: close({
	path:       #RelativePath & =~"^\\.codex/skills/[a-z0-9-]+/scripts/[a-z0-9-]+$" & !~"(^|/)bin/"
	content:    string & =~"^#!/bin/sh\n" & !~"/home/_404/src/contract\\.cuemod" & !~"/[^ \t\n]*/dotfiles/bin"
	executable: true
	provenance: #ProjectionProvenance
})
