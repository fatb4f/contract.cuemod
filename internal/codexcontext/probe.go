package codexcontext

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
)

type CodexProbeOptions struct {
	Command  string
	RepoRoot string
}

type codexRuntimeEvent struct {
	Type string            `json:"type"`
	Item *codexRuntimeItem `json:"item,omitempty"`
}

type codexRuntimeItem struct {
	Type         string                       `json:"type"`
	Tool         string                       `json:"tool,omitempty"`
	Prompt       string                       `json:"prompt,omitempty"`
	AgentsStates map[string]codexRuntimeAgent `json:"agents_states,omitempty"`
}

type codexRuntimeAgent struct {
	Status  string  `json:"status"`
	Message *string `json:"message"`
}

func (h *Harness) RunCodexProbe(
	ctx context.Context,
	options CodexProbeOptions,
	request LiveRequest,
) ([]LiveEvent, error) {
	if request.Schema != LiveRequestSchema {
		return nil, fmt.Errorf("probe request schema %q is not %q", request.Schema, LiveRequestSchema)
	}
	if !slices.Equal(request.AvailableFragmentIDs, h.availableIDs) {
		return nil, fmt.Errorf(
			"probe available fragments = %v, want %v",
			request.AvailableFragmentIDs,
			h.availableIDs,
		)
	}
	if options.Command == "" {
		options.Command = "codex"
	}
	if options.RepoRoot == "" {
		return nil, errors.New("probe repository root is empty")
	}

	selected, err := classifyGenerated(ctx, options.RepoRoot, request.Prompt)
	if err != nil {
		return nil, err
	}
	selectedContext, err := h.expandSelected(selected)
	if err != nil {
		return nil, err
	}

	tempRoot, err := os.MkdirTemp(options.RepoRoot, ".codex-lifecycle-probe-*")
	if err != nil {
		return nil, fmt.Errorf("create probe workspace: %w", err)
	}
	defer os.RemoveAll(tempRoot)

	if err := writeProbeWorkspace(tempRoot, h.availableIDs, selected, selectedContext); err != nil {
		return nil, err
	}

	prompt := fmt.Sprintf(`Runtime lifecycle probe.

Original prompt: %q

Use spawn_agent exactly once. Its prompt must include:
1. The complete agent.hook-hint.v1 additional context injected by UserPromptSubmit.
2. Only the scoped selected context and selected IDs declared in the turn-start instructions.
3. A request that the subagent reply with the exact SCOPED_CONTEXT marker declared there.

Do not add any other fragment ID to the subagent prompt. Wait for the subagent,
then reply with exactly PROBE_OK.`, request.Prompt)

	command := exec.CommandContext(
		ctx,
		options.Command,
		"exec",
		"--json",
		"--ephemeral",
		"--sandbox",
		"read-only",
		"--dangerously-bypass-hook-trust",
		"-C",
		tempRoot,
		prompt,
	)
	command.Dir = options.RepoRoot
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	command.Stdout = &stdout
	command.Stderr = &stderr
	if err := command.Run(); err != nil {
		return nil, fmt.Errorf("run Codex runtime probe: %w: %s", err, strings.TrimSpace(stderr.String()))
	}

	if err := validateCodexRuntime(stdout.Bytes(), selected, selectedContext, h.availableIDs); err != nil {
		return nil, err
	}

	return []LiveEvent{
		{
			Schema:      LiveEventSchema,
			Type:        "turn_start.fragments_available",
			FragmentIDs: slices.Clone(h.availableIDs),
		},
		{
			Schema:      LiveEventSchema,
			Type:        "user_prompt_submit.classified",
			FragmentIDs: slices.Clone(selected),
		},
		{
			Schema:  LiveEventSchema,
			Type:    "runtime.selected_fragments_expanded",
			Context: slices.Clone(selectedContext),
		},
		{
			Schema:  LiveEventSchema,
			Type:    "subagent.scoped_context_expanded",
			Context: slices.Clone(selectedContext),
		},
	}, nil
}

func classifyGenerated(ctx context.Context, repoRoot, prompt string) ([]string, error) {
	input, err := os.CreateTemp("", "codex-lifecycle-classifier-*.json")
	if err != nil {
		return nil, fmt.Errorf("create classifier input: %w", err)
	}
	inputPath := input.Name()
	defer os.Remove(inputPath)

	if err := json.NewEncoder(input).Encode(map[string]any{
		"promptClassifierInput": map[string]string{"prompt": prompt},
	}); err != nil {
		input.Close()
		return nil, fmt.Errorf("encode classifier input: %w", err)
	}
	if err := input.Close(); err != nil {
		return nil, fmt.Errorf("close classifier input: %w", err)
	}

	command := exec.CommandContext(
		ctx,
		"cue",
		"export",
		"./projections/agent-context",
		inputPath,
		"-e",
		"promptClassification",
	)
	command.Dir = repoRoot
	output, err := command.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("run generated classifier: %w: %s", err, strings.TrimSpace(string(output)))
	}

	var classification struct {
		SelectedFragments []string `json:"selectedFragments"`
	}
	if err := json.Unmarshal(output, &classification); err != nil {
		return nil, fmt.Errorf("decode generated classification: %w", err)
	}
	return classification.SelectedFragments, nil
}

func (h *Harness) expandSelected(selected []string) ([]Fragment, error) {
	seen := make(map[string]struct{}, len(selected))
	expanded := make([]Fragment, 0, len(selected))
	for _, id := range selected {
		fragment, exists := h.fragments[id]
		if !exists {
			return nil, fmt.Errorf("classifier selected unavailable fragment %q", id)
		}
		if _, duplicate := seen[id]; duplicate {
			return nil, fmt.Errorf("classifier selected duplicate fragment %q", id)
		}
		seen[id] = struct{}{}
		expanded = append(expanded, fragment)
	}
	return expanded, nil
}

func writeProbeWorkspace(
	root string,
	availableIDs []string,
	selected []string,
	selectedContext []Fragment,
) error {
	agents := fmt.Sprintf(
		`# Runtime Probe

Turn-start available fragment IDs:

%s

Scoped selected fragment IDs:

%s

Scoped selected context:

%s

The selected context above is the only fragment context that may be sent to a
subagent. The subagent must reply exactly:

SCOPED_CONTEXT:%s
`,
		mustJSON(availableIDs),
		mustJSON(selected),
		mustJSON(selectedContext),
		mustJSON(selected),
	)
	if err := os.WriteFile(filepath.Join(root, "AGENTS.md"), []byte(agents), 0o600); err != nil {
		return fmt.Errorf("write probe AGENTS.md: %w", err)
	}
	return nil
}

func validateCodexRuntime(
	data []byte,
	selected []string,
	selectedContext []Fragment,
	availableIDs []string,
) error {
	var sawThreadStart bool
	var sawTurnStart bool
	var sawTurnComplete bool
	var spawnPrompt string
	var childMessage string

	scanner := bufio.NewScanner(bytes.NewReader(data))
	scanner.Buffer(make([]byte, 64*1024), 1024*1024)
	for scanner.Scan() {
		var event codexRuntimeEvent
		if err := json.Unmarshal(scanner.Bytes(), &event); err != nil {
			return fmt.Errorf("decode Codex runtime event: %w", err)
		}
		switch event.Type {
		case "thread.started":
			sawThreadStart = true
		case "turn.started":
			sawTurnStart = true
		case "turn.completed":
			sawTurnComplete = true
		case "item.completed":
			if event.Item == nil || event.Item.Type != "collab_tool_call" {
				continue
			}
			switch event.Item.Tool {
			case "spawn_agent":
				spawnPrompt = event.Item.Prompt
			case "wait":
				for _, state := range event.Item.AgentsStates {
					if state.Status == "completed" && state.Message != nil {
						childMessage = *state.Message
					}
				}
			}
		}
	}
	if err := scanner.Err(); err != nil {
		return fmt.Errorf("read Codex runtime events: %w", err)
	}
	if !sawThreadStart || !sawTurnStart || !sawTurnComplete {
		return errors.New("Codex runtime did not emit a complete thread and turn lifecycle")
	}
	if spawnPrompt == "" {
		return errors.New("Codex runtime did not emit a completed spawn_agent call")
	}
	if !strings.Contains(spawnPrompt, `"schema":"agent.hook-hint.v1"`) {
		return fmt.Errorf(
			"spawn_agent prompt did not contain observed UserPromptSubmit hook context: %q",
			spawnPrompt,
		)
	}

	contextJSON := mustJSON(selectedContext)
	if !strings.Contains(spawnPrompt, contextJSON) {
		return errors.New("spawn_agent prompt did not contain canonical selected context")
	}
	selectedSet := make(map[string]struct{}, len(selected))
	for _, id := range selected {
		selectedSet[id] = struct{}{}
	}
	for _, id := range availableIDs {
		if _, selected := selectedSet[id]; !selected && strings.Contains(spawnPrompt, id) {
			return fmt.Errorf("spawn_agent prompt exposed unselected fragment %q", id)
		}
	}

	wantChild := "SCOPED_CONTEXT:" + mustJSON(selected)
	if strings.TrimSpace(childMessage) != wantChild {
		return fmt.Errorf("subagent response %q, want %q", strings.TrimSpace(childMessage), wantChild)
	}
	return nil
}

func mustJSON(value any) string {
	data, err := json.Marshal(value)
	if err != nil {
		panic(err)
	}
	return string(data)
}
