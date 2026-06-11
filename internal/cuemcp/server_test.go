package cuemcp

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"github.com/mark3labs/mcp-go/mcp"
)

func TestResolveAndSearchImplementation(t *testing.T) {
	root := filepath.Clean(filepath.Join("..", ".."))
	runtime := New(root)
	record, projection, err := runtime.Resolve(context.Background(), resolveInput{
		Prompt:     "Does the WezTerm sessionizer use smart-splits for workspace switching?",
		CWD:        "/home/_404/src/dotfiles",
		Candidates: []string{"workspace-lifecycle"},
	})
	if err != nil {
		t.Fatal(err)
	}
	decision := projection["decision"].(map[string]any)
	if decision["mode"] != "read-only" {
		t.Fatalf("mode = %v, want read-only", decision["mode"])
	}
	result, searchErr := runtime.Search(context.Background(), searchInput{
		Schema:       "agent.search-implementation.request.v1",
		ProjectionID: record.ID,
		ArtifactIDs:  []string{"df:artifact/wezterm-smart-splits-lua"},
		Intent:       "determine whether sessionizer uses smart-splits for workspace switching",
		Terms:        []string{"IS_NVIM", "ActivatePaneDirection", "AdjustPaneSize"},
		ResultLimit:  50,
	})
	if searchErr != nil {
		data, _ := json.Marshal(searchErr)
		t.Fatal(string(data))
	}
	execution := result["execution"].(map[string]any)
	if execution["shell"] != false {
		t.Fatalf("shell = %v, want false", execution["shell"])
	}
	if execution["provider_id"] != "df:provider/cue-rg-mcp" {
		t.Fatalf("provider_id = %v", execution["provider_id"])
	}
	invocations := execution["invocations"].([]map[string]any)
	if len(invocations) != 1 || invocations[0]["artifact_id"] != "df:artifact/wezterm-smart-splits-lua" {
		t.Fatalf("invocations = %#v", invocations)
	}
	results := result["results"].([]searchResult)
	if len(results) == 0 {
		t.Fatal("expected implementation evidence")
	}
	for _, evidence := range results {
		if evidence.ID == "" || evidence.EvidenceID != evidence.ID ||
			evidence.ProviderID != "df:provider/cue-rg-mcp" ||
			evidence.ArtifactID != "df:artifact/wezterm-smart-splits-lua" ||
			filepath.IsAbs(evidence.Path) {
			t.Fatalf("invalid evidence: %#v", evidence)
		}
	}
	coverage := result["coverage"].(map[string]any)
	if coverage["negative_claim_allowed"] != false {
		t.Fatalf("coverage = %#v", coverage)
	}
}

func TestResolverArtifactsAuthorizeCUESearchPlan(t *testing.T) {
	root := filepath.Clean(filepath.Join("..", ".."))
	runtime := New(root)
	record, projection, err := runtime.Resolve(context.Background(), resolveInput{
		Prompt:     "Inspect the WezTerm sessionizer implementation",
		CWD:        "/home/_404/src/dotfiles",
		Candidates: []string{"workspace-lifecycle"},
	})
	if err != nil {
		t.Fatal(err)
	}

	artifactID := "df:artifact/wezterm-smart-splits-lua"
	artifacts := projection["artifacts"].([]any)
	var projectedPath string
	for _, item := range artifacts {
		artifact := item.(map[string]any)
		if artifact["id"] == artifactID {
			projectedPath = artifact["path"].(string)
			break
		}
	}
	if projectedPath == "" {
		t.Fatalf("resolver projection omitted %s", artifactID)
	}

	input := searchInput{
		Schema:       "agent.search-implementation.request.v1",
		ProjectionID: record.ID,
		ArtifactIDs:  []string{artifactID},
		Intent:       "inspect implementation evidence",
		Terms:        []string{"IS_NVIM"},
		ResultLimit:  10,
	}
	plan, err := runtime.authorizeSearchPlan(context.Background(), map[string]any{"searchPlanInput": map[string]any{
		"envelope": record.Envelope,
		"request":  input,
	}})
	if err != nil {
		t.Fatal(err)
	}
	if plan.Backend != "rg" || plan.Shell || len(plan.Targets) != 1 {
		t.Fatalf("CUE search plan = %#v", plan)
	}
	if plan.Targets[0].ArtifactID != artifactID || plan.Targets[0].Path != projectedPath {
		t.Fatalf("CUE target = %#v, projected path = %q", plan.Targets[0], projectedPath)
	}
	argv := rgArgv(plan.Terms, plan.Targets[0].Path)
	if argv[0] != "rg" || argv[len(argv)-1] != projectedPath {
		t.Fatalf("Go rg argv = %#v", argv)
	}
}

func TestSearchRejectsUnknownProjection(t *testing.T) {
	runtime := New(filepath.Clean(filepath.Join("..", "..")))
	_, searchErr := runtime.Search(context.Background(), searchInput{
		Schema:       "agent.search-implementation.request.v1",
		ProjectionID: "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		ArtifactIDs:  []string{"df:artifact/wezterm-config-source"},
		Intent:       "search",
		Terms:        []string{"mux"},
		ResultLimit:  10,
	})
	if searchErr == nil || searchErr["code"] != "projection_not_found" {
		t.Fatalf("error = %#v", searchErr)
	}
}

func TestSearchHandlerWrapsModeledError(t *testing.T) {
	runtime := New(filepath.Clean(filepath.Join("..", "..")))
	request := mcp.CallToolRequest{}
	request.Params.Arguments = map[string]any{
		"schema":        "agent.search-implementation.request.v1",
		"projection_id": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		"artifact_ids":  []string{"df:artifact/wezterm-config-source"},
		"intent":        "search",
		"terms":         []string{"mux"},
		"result_limit":  10,
	}
	result, err := runtime.handleSearch(context.Background(), request)
	if err != nil {
		t.Fatal(err)
	}
	var envelope map[string]any
	if err := json.Unmarshal([]byte(resultText(t, result)), &envelope); err != nil {
		t.Fatal(err)
	}
	if envelope["provider_id"] != "df:provider/cue-rg-mcp" {
		t.Fatalf("error envelope = %#v", envelope)
	}
	payload := envelope["result"].(map[string]any)
	if payload["code"] != "projection_not_found" {
		t.Fatalf("error payload = %#v", payload)
	}
}

func TestLookupAndValidateHandlersWrapModeledErrors(t *testing.T) {
	runtime := New(filepath.Clean(filepath.Join("..", "..")))
	for name, handler := range map[string]func(context.Context, mcp.CallToolRequest) (*mcp.CallToolResult, error){
		"lookup":   runtime.handleLookup,
		"validate": runtime.handleValidate,
	} {
		t.Run(name, func(t *testing.T) {
			request := mcp.CallToolRequest{}
			request.Params.Arguments = map[string]any{
				"projection_id": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
			}
			result, err := handler(context.Background(), request)
			if err != nil {
				t.Fatal(err)
			}
			var envelope map[string]any
			if err := json.Unmarshal([]byte(resultText(t, result)), &envelope); err != nil {
				t.Fatal(err)
			}
			payload := envelope["result"].(map[string]any)
			if payload["code"] != "projection_not_found" {
				t.Fatalf("error payload = %#v", payload)
			}
		})
	}
}

func TestSearchRejectsArtifactOutsideProjection(t *testing.T) {
	root := filepath.Clean(filepath.Join("..", ".."))
	runtime := New(root)
	record, _, err := runtime.Resolve(context.Background(), resolveInput{
		Prompt:     "Inspect the WezTerm sessionizer",
		CWD:        "/home/_404/src/dotfiles",
		Candidates: []string{"workspace-lifecycle"},
	})
	if err != nil {
		t.Fatal(err)
	}
	_, searchErr := runtime.Search(context.Background(), searchInput{
		Schema:       "agent.search-implementation.request.v1",
		ProjectionID: record.ID,
		ArtifactIDs:  []string{"df:artifact/session-generated-executable"},
		Intent:       "search",
		Terms:        []string{"mux"},
		ResultLimit:  10,
	})
	if searchErr == nil || searchErr["code"] != "invalid_search_contract" {
		t.Fatalf("error = %#v", searchErr)
	}
}

func TestMain(m *testing.M) {
	os.Exit(m.Run())
}
