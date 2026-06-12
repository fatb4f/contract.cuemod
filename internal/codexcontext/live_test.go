package codexcontext

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestObserveLiveProjectsSharedReport(t *testing.T) {
	harness := loadHarness(t)
	events, err := os.Open(filepath.Join("testdata", "live_events.jsonl"))
	if err != nil {
		t.Fatal(err)
	}
	defer events.Close()

	result, err := harness.ObserveLive(events)
	if err != nil {
		t.Fatal(err)
	}
	if result.Schema != ReportSchema {
		t.Fatalf("report schema = %q", result.Schema)
	}
	if len(result.SubagentExpandedContext) != 1 {
		t.Fatalf("subagent context length = %d, want 1", len(result.SubagentExpandedContext))
	}
	if got := result.SubagentExpandedContext[0].ID; got != "generated.agent-runtime-assets" {
		t.Fatalf("subagent fragment = %q", got)
	}
}

func TestObserveLiveRejectsUnknownFragment(t *testing.T) {
	harness := loadHarness(t)
	events := strings.NewReader(`
{"schema":"agent.codex-lifecycle-event.v1","type":"turn_start.fragments_available","fragmentIDs":["registry.agent-capability-routes","skill.resolve-agent-context","generated.agent-runtime-assets"]}
{"schema":"agent.codex-lifecycle-event.v1","type":"user_prompt_submit.classified","fragmentIDs":["fragment.not-declared"]}
{"schema":"agent.codex-lifecycle-event.v1","type":"runtime.selected_fragments_expanded","context":[]}
{"schema":"agent.codex-lifecycle-event.v1","type":"subagent.scoped_context_expanded","context":[]}
`)

	_, err := harness.ObserveLive(events)
	if err == nil || !strings.Contains(err.Error(), `unavailable fragment "fragment.not-declared"`) {
		t.Fatalf("error = %v", err)
	}
}

func TestObserveLiveRejectsUnselectedSubagentContext(t *testing.T) {
	harness := loadHarness(t)
	events := strings.NewReader(`
{"schema":"agent.codex-lifecycle-event.v1","type":"turn_start.fragments_available","fragmentIDs":["registry.agent-capability-routes","skill.resolve-agent-context","generated.agent-runtime-assets"]}
{"schema":"agent.codex-lifecycle-event.v1","type":"user_prompt_submit.classified","fragmentIDs":["generated.agent-runtime-assets"]}
{"schema":"agent.codex-lifecycle-event.v1","type":"runtime.selected_fragments_expanded","context":[{"id":"generated.agent-runtime-assets","source":"generated","surface":"turn_start","expectedChannel":"message","expectedItemKind":"message","expectedNativeContextInjection":true}]}
{"schema":"agent.codex-lifecycle-event.v1","type":"subagent.scoped_context_expanded","context":[{"id":"registry.agent-capability-routes","source":"registry","surface":"turn_start","expectedChannel":"message","expectedItemKind":"message","expectedNativeContextInjection":true}]}
`)

	_, err := harness.ObserveLive(events)
	if err == nil || !strings.Contains(err.Error(), "subagent context is not scoped") {
		t.Fatalf("error = %v", err)
	}
}

func TestObserveLiveRejectsLifecycleReordering(t *testing.T) {
	harness := loadHarness(t)
	events := strings.NewReader(`
{"schema":"agent.codex-lifecycle-event.v1","type":"user_prompt_submit.classified","fragmentIDs":[]}
{"schema":"agent.codex-lifecycle-event.v1","type":"turn_start.fragments_available","fragmentIDs":["registry.agent-capability-routes","skill.resolve-agent-context","generated.agent-runtime-assets"]}
{"schema":"agent.codex-lifecycle-event.v1","type":"runtime.selected_fragments_expanded","context":[]}
{"schema":"agent.codex-lifecycle-event.v1","type":"subagent.scoped_context_expanded","context":[]}
`)

	_, err := harness.ObserveLive(events)
	if err == nil || !strings.Contains(err.Error(), "live event 0 type") {
		t.Fatalf("error = %v", err)
	}
}
