//go:build integration

package codexcontext

import (
	"context"
	"encoding/json"
	"os"
	"reflect"
	"testing"
	"time"
)

func TestLiveCodexRuntimeMatchesDeterministicHarness(t *testing.T) {
	commandJSON := os.Getenv("CODEX_CONTEXT_LIVE_COMMAND_JSON")
	if commandJSON == "" {
		commandJSON = `["go","run","./cmd/probe-codex-lifecycle"]`
	}

	var command []string
	if err := json.Unmarshal([]byte(commandJSON), &command); err != nil {
		t.Fatalf("decode CODEX_CONTEXT_LIVE_COMMAND_JSON: %v", err)
	}

	harness := loadHarness(t)
	const prompt = "How does agent context apply when switching WezTerm sessions?"
	deterministic, err := harness.Run(prompt, generatedClassifier(t))
	if err != nil {
		t.Fatal(err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	live, err := harness.RunLiveCommand(ctx, command, "../..", prompt)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(live, deterministic) {
		t.Fatalf("live report = %#v, deterministic report = %#v", live, deterministic)
	}
}
