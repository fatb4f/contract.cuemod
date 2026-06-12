package codexcontext

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestValidateCodexRuntimeAcceptsScopedSubagent(t *testing.T) {
	selected := []string{"generated.agent-runtime-assets"}
	context := []Fragment{{
		ID:                             "generated.agent-runtime-assets",
		Source:                         "generated",
		Surface:                        "turn_start",
		ExpectedChannel:                "message",
		ExpectedItemKind:               "message",
		ExpectedNativeContextInjection: true,
	}}
	events := encodeRuntimeEvents(t, []codexRuntimeEvent{
		{Type: "thread.started"},
		{Type: "turn.started"},
		{
			Type: "item.completed",
			Item: &codexRuntimeItem{
				Type:   "collab_tool_call",
				Tool:   "spawn_agent",
				Prompt: `{"schema":"agent.hook-hint.v1"} scoped ` + mustJSON(context),
			},
		},
		{
			Type: "item.completed",
			Item: &codexRuntimeItem{
				Type: "collab_tool_call",
				Tool: "wait",
				AgentsStates: map[string]codexRuntimeAgent{
					"child": {
						Status:  "completed",
						Message: stringPointer("SCOPED_CONTEXT:" + mustJSON(selected)),
					},
				},
			},
		},
		{Type: "turn.completed"},
	})

	err := validateCodexRuntime(
		[]byte(events),
		selected,
		context,
		[]string{
			"registry.agent-capability-routes",
			"skill.resolve-agent-context",
			"generated.agent-runtime-assets",
		},
	)
	if err != nil {
		t.Fatal(err)
	}
}

func TestValidateCodexRuntimeRejectsUnselectedFragment(t *testing.T) {
	selected := []string{"generated.agent-runtime-assets"}
	context := []Fragment{{
		ID:                             "generated.agent-runtime-assets",
		Source:                         "generated",
		Surface:                        "turn_start",
		ExpectedChannel:                "message",
		ExpectedItemKind:               "message",
		ExpectedNativeContextInjection: true,
	}}
	events := encodeRuntimeEvents(t, []codexRuntimeEvent{
		{Type: "thread.started"},
		{Type: "turn.started"},
		{
			Type: "item.completed",
			Item: &codexRuntimeItem{
				Type:   "collab_tool_call",
				Tool:   "spawn_agent",
				Prompt: `{"schema":"agent.hook-hint.v1"} ` + mustJSON(context) + " registry.agent-capability-routes",
			},
		},
		{
			Type: "item.completed",
			Item: &codexRuntimeItem{
				Type: "collab_tool_call",
				Tool: "wait",
				AgentsStates: map[string]codexRuntimeAgent{
					"child": {
						Status:  "completed",
						Message: stringPointer("SCOPED_CONTEXT:" + mustJSON(selected)),
					},
				},
			},
		},
		{Type: "turn.completed"},
	})

	err := validateCodexRuntime(
		[]byte(events),
		selected,
		context,
		[]string{
			"registry.agent-capability-routes",
			"skill.resolve-agent-context",
			"generated.agent-runtime-assets",
		},
	)
	if err == nil || !strings.Contains(err.Error(), "exposed unselected fragment") {
		t.Fatalf("error = %v", err)
	}
}

func encodeRuntimeEvents(t *testing.T, events []codexRuntimeEvent) string {
	t.Helper()

	var lines []string
	for _, event := range events {
		data, err := json.Marshal(event)
		if err != nil {
			t.Fatal(err)
		}
		lines = append(lines, string(data))
	}
	return strings.Join(lines, "\n")
}

func stringPointer(value string) *string {
	return &value
}
