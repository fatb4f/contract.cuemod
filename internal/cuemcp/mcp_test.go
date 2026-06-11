package cuemcp

import (
	"context"
	"encoding/json"
	"path/filepath"
	"testing"
	"time"

	"github.com/mark3labs/mcp-go/client"
	"github.com/mark3labs/mcp-go/mcp"
)

func TestMCPResolveThenSearch(t *testing.T) {
	root, err := filepath.Abs(filepath.Join("..", ".."))
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	mcpClient, err := client.NewStdioMCPClient(
		"go",
		[]string{"CUE_CONTRACT_ROOT=" + root},
		"-C",
		root,
		"run",
		"./cmd/cue-mcp",
	)
	if err != nil {
		t.Fatal(err)
	}
	defer mcpClient.Close()

	initialize := mcp.InitializeRequest{}
	initialize.Params.ProtocolVersion = mcp.LATEST_PROTOCOL_VERSION
	initialize.Params.ClientInfo = mcp.Implementation{Name: "cue-mcp-test", Version: "1.0.0"}
	if _, err := mcpClient.Initialize(ctx, initialize); err != nil {
		t.Fatal(err)
	}

	tools, err := mcpClient.ListTools(ctx, mcp.ListToolsRequest{})
	if err != nil {
		t.Fatal(err)
	}
	if len(tools.Tools) != 5 {
		t.Fatalf("tool count = %d, want 5", len(tools.Tools))
	}
	foundSearch := false
	for _, available := range tools.Tools {
		if available.Name == "rg" {
			t.Fatal("raw rg must not be agent-visible")
		}
		if available.Name == "search_implementation" {
			foundSearch = true
		}
	}
	if !foundSearch {
		t.Fatal("search_implementation MCP tool is missing")
	}

	providers := mcp.CallToolRequest{}
	providers.Params.Name = "list_semantic_providers"
	providerResult, err := mcpClient.CallTool(ctx, providers)
	if err != nil {
		t.Fatal(err)
	}
	var providerCatalog map[string]any
	if err := json.Unmarshal([]byte(resultText(t, providerResult)), &providerCatalog); err != nil {
		t.Fatal(err)
	}
	providerPayload := providerCatalog["result"].(map[string]any)
	if providerPayload["schema"] != "agent.semantic-providers.response.v1" {
		t.Fatalf("provider catalog = %#v", providerCatalog)
	}

	resolve := mcp.CallToolRequest{}
	resolve.Params.Name = "resolve_agent_context"
	resolve.Params.Arguments = map[string]any{
		"prompt":     "Does the WezTerm sessionizer use smart-splits for workspace switching?",
		"cwd":        "/home/_404/src/dotfiles",
		"candidates": []string{"workspace-lifecycle"},
	}
	resolveResult, err := mcpClient.CallTool(ctx, resolve)
	if err != nil {
		t.Fatal(err)
	}
	var resolved map[string]any
	if err := json.Unmarshal([]byte(resultText(t, resolveResult)), &resolved); err != nil {
		t.Fatal(err)
	}
	resolvedPayload := resolved["result"].(map[string]any)

	search := mcp.CallToolRequest{}
	search.Params.Name = "search_implementation"
	search.Params.Arguments = map[string]any{
		"schema":        "agent.search-implementation.request.v1",
		"projection_id": resolvedPayload["projection_id"],
		"artifact_ids":  []string{"df:artifact/wezterm-smart-splits-lua"},
		"intent":        "determine whether sessionizer uses smart-splits for workspace switching",
		"terms":         []string{"IS_NVIM", "ActivatePaneDirection", "AdjustPaneSize"},
		"result_limit":  50,
	}
	searchResult, err := mcpClient.CallTool(ctx, search)
	if err != nil {
		t.Fatal(err)
	}
	var searched map[string]any
	if err := json.Unmarshal([]byte(resultText(t, searchResult)), &searched); err != nil {
		t.Fatal(err)
	}
	searchedPayload := searched["result"].(map[string]any)
	if searchedPayload["schema"] != "agent.search-implementation.response.v1" {
		t.Fatalf("search outcome = %#v", searched)
	}
	execution := searchedPayload["execution"].(map[string]any)
	if execution["shell"] != false {
		t.Fatalf("shell = %v, want false", execution["shell"])
	}
}

func resultText(t *testing.T, result *mcp.CallToolResult) string {
	t.Helper()
	if result.IsError || len(result.Content) != 1 {
		t.Fatalf("tool result = %#v", result)
	}
	content, ok := result.Content[0].(mcp.TextContent)
	if ok {
		return content.Text
	}
	generic, ok := result.Content[0].(map[string]any)
	if !ok {
		t.Fatalf("content = %#v", result.Content[0])
	}
	text, ok := generic["text"].(string)
	if !ok {
		t.Fatalf("content text = %#v", generic)
	}
	return text
}
