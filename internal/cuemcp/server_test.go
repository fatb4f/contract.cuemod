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
		Intent:       "determine whether sessionizer uses smart-splits for workspace switching",
		Terms:        []string{"smart_splits", "SwitchToWorkspace", "get_workspace_names"},
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
	argv := execution["argv"].([]string)
	if len(argv) == 0 || argv[0] != "rg" {
		t.Fatalf("argv = %#v", argv)
	}
	results := result["results"].([]searchResult)
	if len(results) == 0 {
		t.Fatal("expected implementation evidence")
	}
	for _, evidence := range results {
		if evidence.ID == "" || filepath.IsAbs(evidence.Path) {
			t.Fatalf("invalid evidence: %#v", evidence)
		}
	}
}

func TestSearchRejectsUnknownProjection(t *testing.T) {
	runtime := New(filepath.Clean(filepath.Join("..", "..")))
	_, searchErr := runtime.Search(context.Background(), searchInput{
		Schema:       "agent.search-implementation.request.v1",
		ProjectionID: "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		Intent:       "search",
		Terms:        []string{"mux"},
		ResultLimit:  10,
	})
	if searchErr == nil || searchErr["code"] != "projection_not_found" {
		t.Fatalf("error = %#v", searchErr)
	}
}

func TestMain(m *testing.M) {
	os.Exit(m.Run())
}
