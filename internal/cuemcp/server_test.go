package cuemcp

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
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
