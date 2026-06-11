package agentskill

#ScriptAsset: close({
	path:       #RelativePath & =~"^\\.codex/skills/[a-z0-9-]+/scripts/[a-z0-9-]+$" & !~"(^|/)bin/"
	content:    string & =~"^#!/bin/sh\n" & !~"/home/_404/src/contract\\.cuemod/bin"
	executable: true
	provenance: #ProjectionProvenance
})
