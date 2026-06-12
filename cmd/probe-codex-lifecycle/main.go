package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/fatb4f/contract.cuemod/runtime/internal/codexcontext"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run() error {
	var request codexcontext.LiveRequest
	if err := json.NewDecoder(os.Stdin).Decode(&request); err != nil {
		return fmt.Errorf("decode lifecycle probe request: %w", err)
	}

	repoRoot, err := os.Getwd()
	if err != nil {
		return fmt.Errorf("get repository root: %w", err)
	}
	projectionJSON, err := os.ReadFile(filepath.Join(repoRoot, "generated", "agent_context_projection.json"))
	if err != nil {
		return fmt.Errorf("read generated projection: %w", err)
	}
	turnStartJSON, err := os.ReadFile(filepath.Join(repoRoot, "generated", "turn_start_context_fragments.json"))
	if err != nil {
		return fmt.Errorf("read generated turn-start fragments: %w", err)
	}
	harness, err := codexcontext.Load(projectionJSON, turnStartJSON)
	if err != nil {
		return err
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()
	events, err := harness.RunCodexProbe(ctx, codexcontext.CodexProbeOptions{
		Command:  os.Getenv("CODEX_CONTEXT_CODEX_BIN"),
		RepoRoot: repoRoot,
	}, request)
	if err != nil {
		return err
	}

	encoder := json.NewEncoder(os.Stdout)
	for _, event := range events {
		if err := encoder.Encode(event); err != nil {
			return fmt.Errorf("encode lifecycle event: %w", err)
		}
	}
	return nil
}
