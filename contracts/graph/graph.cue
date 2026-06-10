package graph

#ProviderID:       string & =~"^df:provider/[a-z0-9._-]+$"
#ProjectionID:     string & =~"^df:projection/[a-z0-9._-]+$"
#ContractID:       string & =~"^df:contract/[a-z0-9._-]+$"
#NodeID:           string & =~"^df:node/[a-z0-9._-]+$"
#ImplementationID: string & =~"^df:implementation/[a-z0-9._-]+$"
#ArtifactID:       string & =~"^df:artifact/[a-z0-9._-]+$"
#SymbolID:         string & =~"^df:symbol/[a-z0-9._-]+$"
#EvidenceID:       string & =~"^df:evidence/[a-z0-9._-]+$"

#ArtifactAccess: close({
	artifact_id: #ArtifactID
	raw_path?:   string & !~"^/"

	access: close({
		direct: false
		providers: [#ProviderID, ...#ProviderID]
	})
})

#Evidence: close({
	evidence_id: #EvidenceID
	provider_id: #ProviderID
	artifact_id: #ArtifactID
	summary:     string & !=""
	symbol_id?:  #SymbolID
})
