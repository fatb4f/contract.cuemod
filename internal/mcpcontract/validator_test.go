package mcpcontract

import (
	"context"
	"path/filepath"
	"testing"
)

func TestValidateRejectsUnboundProvider(t *testing.T) {
	root := filepath.Clean(filepath.Join("..", ".."))
	result := Result{
		ProviderID: "df:provider/cue-lsp-mcp",
		Provider: Provider{
			Kind:      "invented-provider",
			Protocol:  "mcp-tool",
			Authority: "cue-graph",
		},
		Capability: "validate",
		Claim: Claim{
			Kind: "context-projection",
		},
		Result: map[string]any{},
	}
	if err := Validate(context.Background(), root, "#ResolveAgentContextMCPResult", result); err == nil {
		t.Fatal("invalid provider kind unexpectedly validated")
	}
}
