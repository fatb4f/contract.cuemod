package transaction

import (
	"context"
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func TestFinalizePatchCreatesCommitRefMetadataAndEvidence(t *testing.T) {
	repo := initStageRepository(t)
	writeFile(t, repo, "selected.txt", "finalized\n")
	runGit(t, repo, "add", "selected.txt")

	request := FinalizePatchRequest{
		PatchID: "patch-1", Message: "patch one",
		PreparedEvidenceURI: "evidence://prepared/patch-1",
		PreparedTreeOID:     runGitOutput(t, repo, "write-tree"),
	}
	transactionRequest, outcome, err := NewFinalizePatchTransactionRequest(repo, request)
	if err != nil {
		t.Fatal(err)
	}
	result, err := finalizeRunner(repo).Run(context.Background(), transactionRequest)
	if err != nil {
		t.Fatalf("Run() error = %v, result = %#v", err, result)
	}
	if !result.OK || result.State != StateCommitted {
		t.Fatalf("result = %#v", result)
	}
	if ref := runGitOutput(t, repo, "rev-parse", outcome.StackRef); ref != outcome.CommitOID {
		t.Fatalf("stack ref = %s, commit = %s", ref, outcome.CommitOID)
	}
	if parent := runGitOutput(t, repo, "show", "-s", "--format=%P", outcome.CommitOID); parent != result.Preflight.HeadOID {
		t.Fatalf("parent = %s, want %s", parent, result.Preflight.HeadOID)
	}
	metadataPath := strings.TrimPrefix(outcome.MetadataURI, "file://")
	content, err := os.ReadFile(metadataPath)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(content), request.PreparedEvidenceURI) ||
		!strings.Contains(string(content), outcome.CommitOID) {
		t.Fatalf("metadata = %s", content)
	}
	assertEvidenceKinds(t, result.Evidence, "transaction", "snapshot", "journal", "postflight")
}

func TestFinalizePatchPreflightStates(t *testing.T) {
	tests := []struct {
		name  string
		setup func(*testing.T, string)
	}{
		{name: "empty"},
		{name: "dirty", setup: func(t *testing.T, repo string) {
			writeFile(t, repo, "selected.txt", "staged\n")
			runGit(t, repo, "add", "selected.txt")
			writeFile(t, repo, "selected.txt", "unstaged after stage\n")
		}},
		{name: "conflict", setup: func(t *testing.T, repo string) {
			writeFile(t, repo, "selected.txt", "staged\n")
			runGit(t, repo, "add", "selected.txt")
			gitDir := runGitOutput(t, repo, "rev-parse", "--git-dir")
			if !filepath.IsAbs(gitDir) {
				gitDir = filepath.Join(repo, gitDir)
			}
			if err := os.WriteFile(filepath.Join(gitDir, "MERGE_HEAD"), []byte(strings.Repeat("a", 40)+"\n"), 0o600); err != nil {
				t.Fatal(err)
			}
		}},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			repo := initStageRepository(t)
			if test.setup != nil {
				test.setup(t, repo)
			}
			request, _, err := NewFinalizePatchTransactionRequest(repo, FinalizePatchRequest{
				PatchID: "patch-1", Message: "patch one",
				PreparedEvidenceURI: "evidence://prepared/patch-1",
				PreparedTreeOID:     runGitOutput(t, repo, "write-tree"),
			})
			if err != nil {
				t.Fatal(err)
			}
			result, err := finalizeRunner(repo).Run(context.Background(), request)
			if err == nil || result == nil || result.State != StateAborted || result.FailureClass != FailurePreflight {
				t.Fatalf("result=%#v err=%v", result, err)
			}
			if output := runGitAllowFailure(repo, "rev-parse", "--verify", "refs/stack/patches/patch-1"); output != "" {
				t.Fatalf("stack ref unexpectedly exists: %s", output)
			}
		})
	}
}

func TestFinalizePatchRefFailureDoesNotMoveRef(t *testing.T) {
	repo := initStageRepository(t)
	writeFile(t, repo, "selected.txt", "staged\n")
	runGit(t, repo, "add", "selected.txt")
	request, _, err := NewFinalizePatchTransactionRequest(repo, FinalizePatchRequest{
		PatchID: "patch-1", Message: "patch one",
		PreparedEvidenceURI: "evidence://prepared/patch-1",
		PreparedTreeOID:     runGitOutput(t, repo, "write-tree"),
	})
	if err != nil {
		t.Fatal(err)
	}
	mutation := request.Mutation.(FinalizePatchMutation)
	mutation.UpdateRef = func(context.Context, string, string, string, string) error {
		return errors.New("injected ref failure")
	}
	request.Mutation = mutation
	result, err := finalizeRunner(repo).Run(context.Background(), request)
	if err == nil || result.State != StateRolledBack {
		t.Fatalf("result=%#v err=%v", result, err)
	}
	if output := runGitAllowFailure(repo, "rev-parse", "--verify", mutation.Outcome.StackRef); output != "" {
		t.Fatalf("stack ref unexpectedly exists: %s", output)
	}
	assertEvidenceKinds(t, result.Evidence, "rollback", "diagnostic")
}

func TestFinalizePatchRejectsPreparedEvidenceForDifferentTree(t *testing.T) {
	repo := initStageRepository(t)
	preparedTree := runGitOutput(t, repo, "write-tree")
	writeFile(t, repo, "selected.txt", "staged later\n")
	runGit(t, repo, "add", "selected.txt")
	request, _, err := NewFinalizePatchTransactionRequest(repo, FinalizePatchRequest{
		PatchID: "patch-1", Message: "patch one",
		PreparedEvidenceURI: "evidence://prepared/patch-1",
		PreparedTreeOID:     preparedTree,
	})
	if err != nil {
		t.Fatal(err)
	}
	result, err := finalizeRunner(repo).Run(context.Background(), request)
	if err == nil || result.State != StateAborted || result.FailureClass != FailurePreflight {
		t.Fatalf("result=%#v err=%v", result, err)
	}
	if output := runGitAllowFailure(repo, "rev-parse", "--verify", "refs/stack/patches/patch-1"); output != "" {
		t.Fatalf("stack ref unexpectedly exists: %s", output)
	}
}

func TestFinalizePatchMetadataFailureRollsBackRef(t *testing.T) {
	repo := initStageRepository(t)
	writeFile(t, repo, "selected.txt", "staged\n")
	runGit(t, repo, "add", "selected.txt")
	request, outcome, err := NewFinalizePatchTransactionRequest(repo, FinalizePatchRequest{
		PatchID: "patch-1", Message: "patch one",
		PreparedEvidenceURI: "evidence://prepared/patch-1",
		PreparedTreeOID:     runGitOutput(t, repo, "write-tree"),
	})
	if err != nil {
		t.Fatal(err)
	}
	mutation := request.Mutation.(FinalizePatchMutation)
	mutation.WriteMetadata = func(string, []byte) error { return errors.New("injected metadata failure") }
	request.Mutation = mutation
	result, err := finalizeRunner(repo).Run(context.Background(), request)
	if err == nil || result.State != StateRolledBack {
		t.Fatalf("result=%#v err=%v", result, err)
	}
	if output := runGitAllowFailure(repo, "rev-parse", "--verify", outcome.StackRef); output != "" {
		t.Fatalf("stack ref unexpectedly exists: %s", output)
	}
	if _, err := os.Stat(strings.TrimPrefix(outcome.MetadataURI, "file://")); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("metadata stat error = %v", err)
	}
}

func TestFinalizePatchPostflightFailureRestoresExistingState(t *testing.T) {
	repo := initStageRepository(t)
	oldOID := runGitOutput(t, repo, "rev-parse", "HEAD")
	runGit(t, repo, "update-ref", "refs/stack/patches/patch-1", oldOID)
	metadataPath := filepath.Join(repo, ".git", "git-mcp-patches", "patch-1.json")
	writeFile(t, filepath.Join(repo, ".git"), "git-mcp-patches/patch-1.json", "old metadata\n")
	writeFile(t, repo, "selected.txt", "staged\n")
	runGit(t, repo, "add", "selected.txt")

	request, _, err := NewFinalizePatchTransactionRequest(repo, FinalizePatchRequest{
		PatchID: "patch-1", Message: "patch one",
		PreparedEvidenceURI: "evidence://prepared/patch-1",
		PreparedTreeOID:     runGitOutput(t, repo, "write-tree"),
	})
	if err != nil {
		t.Fatal(err)
	}
	request.Validator = validatorFunc(func(context.Context, Repository, View) error {
		return errors.New("injected postflight failure")
	})
	result, err := finalizeRunner(repo).Run(context.Background(), request)
	if err == nil || result.State != StateRolledBack {
		t.Fatalf("result=%#v err=%v", result, err)
	}
	if ref := runGitOutput(t, repo, "rev-parse", "refs/stack/patches/patch-1"); ref != oldOID {
		t.Fatalf("restored ref = %s, want %s", ref, oldOID)
	}
	content, err := os.ReadFile(metadataPath)
	if err != nil || string(content) != "old metadata\n" {
		t.Fatalf("metadata=%q err=%v", content, err)
	}
}

func finalizeRunner(repo string) *Runner {
	return NewRunner(
		LocalRepository(repo),
		GitObserver{StackRefPrefixes: []string{"refs/heads", "refs/stack"}},
		GitSnapshotStore{},
		NewMemoryJournalStore(),
		Dispatcher{Handlers: map[RollbackClass]RollbackHandler{
			RollbackRefOnly: FinalizePatchRollback{},
		}},
		URIEmitter{},
	)
}

func runGitAllowFailure(repo string, args ...string) string {
	command := exec.Command("git", args...)
	command.Dir = repo
	output, err := command.CombinedOutput()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(output))
}
