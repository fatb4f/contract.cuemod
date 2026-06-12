package codexcontext

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os/exec"
	"slices"
)

const (
	LiveEventSchema   = "agent.codex-lifecycle-event.v1"
	LiveRequestSchema = "agent.codex-lifecycle-request.v1"
)

type LiveEvent struct {
	Schema      string     `json:"schema"`
	Type        string     `json:"type"`
	FragmentIDs []string   `json:"fragmentIDs,omitempty"`
	Context     []Fragment `json:"context,omitempty"`
}

type LiveRequest struct {
	Schema               string   `json:"schema"`
	Prompt               string   `json:"prompt"`
	AvailableFragmentIDs []string `json:"availableFragmentIDs"`
}

func (h *Harness) ObserveLive(reader io.Reader) (Result, error) {
	decoder := json.NewDecoder(reader)
	events := make([]LiveEvent, 0, 4)
	for {
		var event LiveEvent
		if err := decoder.Decode(&event); err != nil {
			if errors.Is(err, io.EOF) {
				break
			}
			return Result{}, fmt.Errorf("decode live lifecycle event: %w", err)
		}
		if event.Schema != LiveEventSchema {
			return Result{}, fmt.Errorf("live event schema %q is not %q", event.Schema, LiveEventSchema)
		}
		events = append(events, event)
	}
	if len(events) != 4 {
		return Result{}, fmt.Errorf("live lifecycle emitted %d events, want 4", len(events))
	}

	wantTypes := []string{
		"turn_start.fragments_available",
		"user_prompt_submit.classified",
		"runtime.selected_fragments_expanded",
		"subagent.scoped_context_expanded",
	}
	for index, want := range wantTypes {
		if events[index].Type != want {
			return Result{}, fmt.Errorf("live event %d type %q, want %q", index, events[index].Type, want)
		}
	}

	result := Result{
		Schema:                  ReportSchema,
		Events:                  slices.Clone(wantTypes),
		AvailableFragmentIDs:    slices.Clone(events[0].FragmentIDs),
		SelectedFragmentIDs:     slices.Clone(events[1].FragmentIDs),
		ExpandedContext:         slices.Clone(events[2].Context),
		SubagentExpandedContext: slices.Clone(events[3].Context),
	}
	if err := h.Validate(result); err != nil {
		return Result{}, fmt.Errorf("validate live lifecycle report: %w", err)
	}
	return result, nil
}

func (h *Harness) RunLiveCommand(
	ctx context.Context,
	command []string,
	dir string,
	prompt string,
) (Result, error) {
	if len(command) == 0 || command[0] == "" {
		return Result{}, errors.New("live runtime command is empty")
	}

	request, err := json.Marshal(LiveRequest{
		Schema:               LiveRequestSchema,
		Prompt:               prompt,
		AvailableFragmentIDs: h.availableIDs,
	})
	if err != nil {
		return Result{}, fmt.Errorf("encode live runtime request: %w", err)
	}

	cmd := exec.CommandContext(ctx, command[0], command[1:]...)
	cmd.Dir = dir
	cmd.Stdin = bytes.NewReader(append(request, '\n'))
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		return Result{}, fmt.Errorf("run live runtime command: %w: %s", err, stderr.String())
	}

	return h.ObserveLive(&stdout)
}
