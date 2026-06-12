package codexcontext

import (
	"encoding/json"
	"errors"
	"fmt"
	"slices"
)

const (
	projectionSchema = "agent.context-fragment-projection.v1"
	turnStartSchema  = "agent.turn-start-context-fragments.v1"
	ReportSchema     = "agent.codex-lifecycle-report.v1"
)

type Fragment struct {
	ID                             string `json:"id"`
	Source                         string `json:"source"`
	Surface                        string `json:"surface"`
	ExpectedChannel                string `json:"expectedChannel"`
	ExpectedItemKind               string `json:"expectedItemKind"`
	ExpectedNativeContextInjection bool   `json:"expectedNativeContextInjection"`
}

type projection struct {
	Schema    string     `json:"schema"`
	Fragments []Fragment `json:"fragments"`
}

type turnStartGeneration struct {
	Schema    string              `json:"schema"`
	Fragments []turnStartFragment `json:"fragments"`
}

type turnStartFragment struct {
	Content struct {
		FragmentIDs []string `json:"fragmentIDs"`
	} `json:"content"`
}

type Classifier func(prompt string, availableFragmentIDs []string) ([]string, error)

type Result struct {
	Schema                  string     `json:"schema"`
	Events                  []string   `json:"events"`
	AvailableFragmentIDs    []string   `json:"availableFragmentIDs"`
	SelectedFragmentIDs     []string   `json:"selectedFragmentIDs"`
	ExpandedContext         []Fragment `json:"expandedContext"`
	SubagentExpandedContext []Fragment `json:"subagentExpandedContext"`
}

type Harness struct {
	availableIDs []string
	fragments    map[string]Fragment
}

func Load(projectionJSON, turnStartJSON []byte) (*Harness, error) {
	var declared projection
	if err := json.Unmarshal(projectionJSON, &declared); err != nil {
		return nil, fmt.Errorf("decode projection: %w", err)
	}
	if declared.Schema != projectionSchema {
		return nil, fmt.Errorf("projection schema %q is not %q", declared.Schema, projectionSchema)
	}

	declaredByID := make(map[string]Fragment, len(declared.Fragments))
	for _, fragment := range declared.Fragments {
		if fragment.ID == "" {
			return nil, errors.New("projection contains an empty fragment ID")
		}
		if _, exists := declaredByID[fragment.ID]; exists {
			return nil, fmt.Errorf("projection contains duplicate fragment ID %q", fragment.ID)
		}
		declaredByID[fragment.ID] = fragment
	}

	var generated turnStartGeneration
	if err := json.Unmarshal(turnStartJSON, &generated); err != nil {
		return nil, fmt.Errorf("decode turn-start fragments: %w", err)
	}
	if generated.Schema != turnStartSchema {
		return nil, fmt.Errorf("turn-start schema %q is not %q", generated.Schema, turnStartSchema)
	}

	available := make(map[string]Fragment)
	var availableIDs []string
	for _, container := range generated.Fragments {
		for _, id := range container.Content.FragmentIDs {
			fragment, exists := declaredByID[id]
			if !exists {
				return nil, fmt.Errorf("turn-start fragment %q is undeclared", id)
			}
			if fragment.Surface != "turn_start" ||
				fragment.ExpectedChannel != "message" ||
				fragment.ExpectedItemKind != "message" ||
				!fragment.ExpectedNativeContextInjection {
				return nil, fmt.Errorf("fragment %q is not native turn-start context", id)
			}
			if _, exists := available[id]; exists {
				continue
			}
			available[id] = fragment
			availableIDs = append(availableIDs, id)
		}
	}
	if len(availableIDs) == 0 {
		return nil, errors.New("turn-start registry contains no fragment IDs")
	}

	return &Harness{availableIDs: availableIDs, fragments: available}, nil
}

func (h *Harness) Run(prompt string, classify Classifier) (Result, error) {
	result := Result{
		Schema:               ReportSchema,
		Events:               []string{"turn_start.fragments_available"},
		AvailableFragmentIDs: slices.Clone(h.availableIDs),
	}

	selected, err := classify(prompt, slices.Clone(h.availableIDs))
	result.Events = append(result.Events, "user_prompt_submit.classified")
	if err != nil {
		return result, fmt.Errorf("classify prompt: %w", err)
	}

	seen := make(map[string]struct{}, len(selected))
	for _, id := range selected {
		fragment, exists := h.fragments[id]
		if !exists {
			return result, fmt.Errorf("classifier selected unavailable fragment %q", id)
		}
		if _, duplicate := seen[id]; duplicate {
			return result, fmt.Errorf("classifier selected duplicate fragment %q", id)
		}
		seen[id] = struct{}{}
		result.SelectedFragmentIDs = append(result.SelectedFragmentIDs, id)
		result.ExpandedContext = append(result.ExpandedContext, fragment)
	}
	result.Events = append(result.Events, "runtime.selected_fragments_expanded")

	result.SubagentExpandedContext = slices.Clone(result.ExpandedContext)
	result.Events = append(result.Events, "subagent.scoped_context_expanded")
	if err := h.Validate(result); err != nil {
		return result, fmt.Errorf("validate deterministic lifecycle report: %w", err)
	}
	return result, nil
}

func (h *Harness) Validate(result Result) error {
	if result.Schema != ReportSchema {
		return fmt.Errorf("report schema %q is not %q", result.Schema, ReportSchema)
	}

	wantEvents := []string{
		"turn_start.fragments_available",
		"user_prompt_submit.classified",
		"runtime.selected_fragments_expanded",
		"subagent.scoped_context_expanded",
	}
	if !slices.Equal(result.Events, wantEvents) {
		return fmt.Errorf("lifecycle events = %v, want %v", result.Events, wantEvents)
	}
	if !slices.Equal(result.AvailableFragmentIDs, h.availableIDs) {
		return fmt.Errorf("available fragments = %v, want %v", result.AvailableFragmentIDs, h.availableIDs)
	}

	seen := make(map[string]struct{}, len(result.SelectedFragmentIDs))
	wantExpanded := make([]Fragment, 0, len(result.SelectedFragmentIDs))
	for _, id := range result.SelectedFragmentIDs {
		fragment, exists := h.fragments[id]
		if !exists {
			return fmt.Errorf("report selected unavailable fragment %q", id)
		}
		if _, duplicate := seen[id]; duplicate {
			return fmt.Errorf("report selected duplicate fragment %q", id)
		}
		seen[id] = struct{}{}
		wantExpanded = append(wantExpanded, fragment)
	}
	if !slices.Equal(result.ExpandedContext, wantExpanded) {
		return fmt.Errorf("expanded context does not match selected fragments")
	}
	if !slices.Equal(result.SubagentExpandedContext, wantExpanded) {
		return fmt.Errorf("subagent context is not scoped to selected fragments")
	}
	return nil
}
