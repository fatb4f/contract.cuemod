package codexcontext

import (
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

func loadHarness(t *testing.T) *Harness {
	t.Helper()

	projectionJSON, err := os.ReadFile(filepath.Join("..", "..", "generated", "agent_context_projection.json"))
	if err != nil {
		t.Fatal(err)
	}
	turnStartJSON, err := os.ReadFile(filepath.Join("..", "..", "generated", "turn_start_context_fragments.json"))
	if err != nil {
		t.Fatal(err)
	}
	harness, err := Load(projectionJSON, turnStartJSON)
	if err != nil {
		t.Fatal(err)
	}
	return harness
}

func generatedClassifier(t *testing.T) Classifier {
	t.Helper()

	return func(prompt string, _ []string) ([]string, error) {
		inputPath := filepath.Join(t.TempDir(), "prompt.json")
		input, err := json.Marshal(map[string]any{
			"promptClassifierInput": map[string]string{"prompt": prompt},
		})
		if err != nil {
			return nil, err
		}
		if err := os.WriteFile(inputPath, input, 0o600); err != nil {
			return nil, err
		}

		command := exec.Command("cue", "export", "./projections/agent-context", inputPath, "-e", "promptClassification")
		command.Dir = filepath.Join("..", "..")
		output, err := command.Output()
		if err != nil {
			return nil, err
		}

		var classification struct {
			SelectedFragments []string `json:"selectedFragments"`
		}
		if err := json.Unmarshal(output, &classification); err != nil {
			return nil, err
		}
		return classification.SelectedFragments, nil
	}
}

func TestGeneratedClassifierFeedsRuntimeExpansion(t *testing.T) {
	harness := loadHarness(t)

	result, err := harness.Run("resolve agent context for this task", generatedClassifier(t))
	if err != nil {
		t.Fatal(err)
	}

	want := []string{"registry.agent-capability-routes", "skill.resolve-agent-context"}
	if !reflect.DeepEqual(result.SelectedFragmentIDs, want) {
		t.Fatalf("selected fragments = %v, want %v", result.SelectedFragmentIDs, want)
	}
	if len(result.SubagentExpandedContext) != len(want) {
		t.Fatalf("subagent context length = %d, want %d", len(result.SubagentExpandedContext), len(want))
	}
}

func TestTurnStartPrecedesPromptClassification(t *testing.T) {
	harness := loadHarness(t)
	var observedAvailable []string

	result, err := harness.Run("resolve agent context", func(_ string, available []string) ([]string, error) {
		observedAvailable = available
		return []string{"registry.agent-capability-routes", "skill.resolve-agent-context"}, nil
	})
	if err != nil {
		t.Fatal(err)
	}

	if len(observedAvailable) == 0 {
		t.Fatal("classifier ran before turn-start fragments were available")
	}
	wantEvents := []string{
		"turn_start.fragments_available",
		"user_prompt_submit.classified",
		"runtime.selected_fragments_expanded",
		"subagent.scoped_context_expanded",
	}
	if !reflect.DeepEqual(result.Events, wantEvents) {
		t.Fatalf("event order = %v, want %v", result.Events, wantEvents)
	}
}

func TestSubagentReceivesOnlySelectedExpandedContext(t *testing.T) {
	harness := loadHarness(t)

	result, err := harness.Run("inspect runtime", func(_ string, _ []string) ([]string, error) {
		return []string{"generated.agent-runtime-assets"}, nil
	})
	if err != nil {
		t.Fatal(err)
	}

	if len(result.SubagentExpandedContext) != 1 {
		t.Fatalf("subagent context length = %d, want 1", len(result.SubagentExpandedContext))
	}
	if got := result.SubagentExpandedContext[0].ID; got != "generated.agent-runtime-assets" {
		t.Fatalf("subagent fragment = %q", got)
	}
	for _, fragment := range result.SubagentExpandedContext {
		if fragment.ID == "registry.agent-capability-routes" {
			t.Fatalf("unselected fragment %q was exposed", fragment.ID)
		}
	}
}

func TestInvalidPromptExpandsNoContext(t *testing.T) {
	harness := loadHarness(t)

	result, err := harness.Run("rewrite release notes", func(_ string, _ []string) ([]string, error) {
		return nil, nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(result.ExpandedContext) != 0 || len(result.SubagentExpandedContext) != 0 {
		t.Fatalf("invalid prompt expanded context: %+v", result)
	}
}

func TestUnknownFragmentFailsBeforeExpansion(t *testing.T) {
	harness := loadHarness(t)

	result, err := harness.Run("resolve context", func(_ string, _ []string) ([]string, error) {
		return []string{"fragment.not-declared"}, nil
	})
	if err == nil || !strings.Contains(err.Error(), `unavailable fragment "fragment.not-declared"`) {
		t.Fatalf("error = %v", err)
	}
	if len(result.ExpandedContext) != 0 || len(result.SubagentExpandedContext) != 0 {
		t.Fatalf("unknown fragment was expanded: %+v", result)
	}
}

func TestLoadRejectsUndeclaredTurnStartFragment(t *testing.T) {
	projectionJSON := []byte(`{
		"schema": "agent.context-fragment-projection.v1",
		"fragments": []
	}`)
	turnStartJSON := []byte(`{
		"schema": "agent.turn-start-context-fragments.v1",
		"fragments": [{"content": {"fragmentIDs": ["fragment.not-declared"]}}]
	}`)

	_, err := Load(projectionJSON, turnStartJSON)
	if err == nil || !strings.Contains(err.Error(), `turn-start fragment "fragment.not-declared" is undeclared`) {
		t.Fatalf("error = %v", err)
	}
}
