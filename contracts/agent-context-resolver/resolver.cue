package agentcontextresolver

import "list"

#DeclaredID: string & =~"^[a-z0-9][a-z0-9._-]*$"

#RegistryEntry: close({
	id:    #DeclaredID
	kind:  "fragment" | "role" | "pipeline" | "function-group"
	label: string & !=""
})

#Registry: close({
	fragments:      [...#RegistryEntry]
	roles:          [...#RegistryEntry]
	pipelines:      [...#RegistryEntry]
	functionGroups: [...#RegistryEntry]
})

#Selection: close({
	fragment_ids:      [...#DeclaredID]
	role_ids:          [...#DeclaredID]
	pipeline_ids:      [...#DeclaredID]
	function_group_ids: [...#DeclaredID]
})

#ResolverReport: close({
	schema: "agent.context-resolver.report.v1"
	query:  string & !=""
	selection: #Selection
	routing: {
		fallback: bool
	}
})

#ResolverOutput: close({
	schema:   "agent.context-resolver.output.v1"
	prompt:   string & !=""
	report:   #ResolverReport
	hook: {
		hook_event_name: "UserPromptSubmit"
		additionalContext: string & !=""
	}
})

#RegistryMatch: {
	registry: #Registry
	selection: #Selection

	allowedFragmentIDs: [for entry in registry.fragments {entry.id}]
	allowedRoleIDs: [for entry in registry.roles {entry.id}]
	allowedPipelineIDs: [for entry in registry.pipelines {entry.id}]
	allowedFunctionGroupIDs: [for entry in registry.functionGroups {entry.id}]

	for _, id in selection.fragment_ids {
		list.Contains(allowedFragmentIDs, id)
	}
	for _, id in selection.role_ids {
		list.Contains(allowedRoleIDs, id)
	}
	for _, id in selection.pipeline_ids {
		list.Contains(allowedPipelineIDs, id)
	}
	for _, id in selection.function_group_ids {
		list.Contains(allowedFunctionGroupIDs, id)
	}
}
