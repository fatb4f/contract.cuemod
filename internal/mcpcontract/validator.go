package mcpcontract

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

type Provider struct {
	Kind      string `json:"kind"`
	Authority string `json:"authority"`
	Protocol  string `json:"protocol"`
}

type Claim struct {
	Kind                 string `json:"kind"`
	Complete             bool   `json:"complete"`
	NegativeClaimAllowed bool   `json:"negative_claim_allowed"`
}

type Result struct {
	ProviderID  string   `json:"provider_id"`
	ContractID  string   `json:"contract_id,omitempty"`
	Provider    Provider `json:"provider"`
	Capability  string   `json:"capability"`
	Claim       Claim    `json:"claim"`
	Result      any      `json:"result"`
	Diagnostics []any    `json:"diagnostics,omitempty"`
}

func Validate(ctx context.Context, root, definition string, value Result) error {
	file, err := os.CreateTemp("", "mcp-contract-*.json")
	if err != nil {
		return err
	}
	defer os.Remove(file.Name())

	if err := json.NewEncoder(file).Encode(value); err != nil {
		_ = file.Close()
		return err
	}
	if err := file.Close(); err != nil {
		return err
	}

	cmd := exec.CommandContext(ctx, "cue", "vet", "-c", "-d", definition, ".", file.Name())
	cmd.Dir = root
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("CUE MCP result validation %s failed: %w: %s", definition, err, strings.TrimSpace(string(output)))
	}
	return nil
}
