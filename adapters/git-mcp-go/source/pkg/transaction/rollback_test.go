package transaction

import (
	"context"
	"os"
	"path/filepath"
	"testing"
)

func TestRollbackStageTransactionFromDurableEvidence(t *testing.T) {
	repo := initStageRepository(t)
	artifactRoot := filepath.Join(repo, ".git", "git-mcp-transactions")
	before := runGitOutput(t, repo, "write-tree")
	writeFile(t, repo, "selected.txt", "selected change\n")

	request, err := NewStageTransactionRequest(gitStageBackend{}, StageRequest{
		ActivePatchID: "patch-1",
		Paths:         []string{"selected.txt"},
	})
	if err != nil {
		t.Fatal(err)
	}
	result, err := persistentRunner(repo, artifactRoot).Run(context.Background(), request)
	if err != nil {
		t.Fatal(err)
	}
	if after := runGitOutput(t, repo, "write-tree"); after == before {
		t.Fatal("stage transaction did not change the index")
	}

	response, err := (RollbackService{
		RepoRoot: repo, ArtifactRoot: artifactRoot,
	}).Run(context.Background(), RollbackRequest{
		ActivePatchID: "patch-1", TargetTransactionID: result.TransactionID,
		RollbackClass: RollbackIndexOnly,
	})
	if err != nil {
		t.Fatal(err)
	}
	if !response.OK || response.State != StateRolledBack || !response.Recovery.Recovered {
		t.Fatalf("response = %#v", response)
	}
	if after := runGitOutput(t, repo, "write-tree"); after != before {
		t.Fatalf("restored index tree = %s, want %s", after, before)
	}
	assertEvidenceKinds(t, response.Evidence, "transaction", "rollback", "recovery")
}

func TestRollbackFinalizeTransactionFromDurableEvidence(t *testing.T) {
	repo := initStageRepository(t)
	artifactRoot := filepath.Join(repo, ".git", "git-mcp-transactions")
	writeFile(t, repo, "selected.txt", "finalized\n")
	runGit(t, repo, "add", "selected.txt")

	finalizeRequest := FinalizePatchRequest{
		PatchID: "patch-1", Message: "patch one",
		PreparedEvidenceURI: "evidence://prepared/patch-1",
		PreparedTreeOID:     runGitOutput(t, repo, "write-tree"),
	}
	request, outcome, err := NewFinalizePatchTransactionRequest(repo, finalizeRequest)
	if err != nil {
		t.Fatal(err)
	}
	result, err := persistentRunner(repo, artifactRoot).Run(context.Background(), request)
	if err != nil {
		t.Fatal(err)
	}

	response, err := (RollbackService{
		RepoRoot: repo, ArtifactRoot: artifactRoot,
	}).Run(context.Background(), RollbackRequest{
		ActivePatchID: "patch-1", TargetTransactionID: result.TransactionID,
		RollbackClass: RollbackRefOnly,
	})
	if err != nil {
		t.Fatal(err)
	}
	if !response.OK || response.State != StateRolledBack {
		t.Fatalf("response = %#v", response)
	}
	if output := runGitAllowFailure(repo, "rev-parse", "--verify", outcome.StackRef); output != "" {
		t.Fatalf("stack ref unexpectedly exists: %s", output)
	}
	if _, err := os.Stat(stringsTrimFileURI(outcome.MetadataURI)); !os.IsNotExist(err) {
		t.Fatalf("metadata stat error = %v", err)
	}
}

func TestRollbackRefusesUnrelatedLaterIndexChanges(t *testing.T) {
	repo := initStageRepository(t)
	artifactRoot := filepath.Join(repo, ".git", "git-mcp-transactions")
	writeFile(t, repo, "selected.txt", "selected change\n")
	request, err := NewStageTransactionRequest(gitStageBackend{}, StageRequest{
		ActivePatchID: "patch-1", Paths: []string{"selected.txt"},
	})
	if err != nil {
		t.Fatal(err)
	}
	result, err := persistentRunner(repo, artifactRoot).Run(context.Background(), request)
	if err != nil {
		t.Fatal(err)
	}
	writeFile(t, repo, "other.txt", "later staged change\n")
	runGit(t, repo, "add", "other.txt")
	beforeRollback := runGitOutput(t, repo, "write-tree")

	response, err := (RollbackService{
		RepoRoot: repo, ArtifactRoot: artifactRoot,
	}).Run(context.Background(), RollbackRequest{
		ActivePatchID: "patch-1", TargetTransactionID: result.TransactionID,
		RollbackClass: RollbackIndexOnly,
	})
	if err != nil {
		t.Fatal(err)
	}
	if response.State != StateRollbackPartial || !response.Recovery.ManualRequired {
		t.Fatalf("response = %#v", response)
	}
	if after := runGitOutput(t, repo, "write-tree"); after != beforeRollback {
		t.Fatal("manual-required rollback changed the index")
	}
}

func TestRollbackRefusesLaterChangesToSameStagedPath(t *testing.T) {
	repo := initStageRepository(t)
	artifactRoot := filepath.Join(repo, ".git", "git-mcp-transactions")
	writeFile(t, repo, "selected.txt", "selected change\n")
	request, err := NewStageTransactionRequest(gitStageBackend{}, StageRequest{
		ActivePatchID: "patch-1", Paths: []string{"selected.txt"},
	})
	if err != nil {
		t.Fatal(err)
	}
	result, err := persistentRunner(repo, artifactRoot).Run(context.Background(), request)
	if err != nil {
		t.Fatal(err)
	}
	writeFile(t, repo, "selected.txt", "later selected change\n")
	runGit(t, repo, "add", "selected.txt")
	beforeRollback := runGitOutput(t, repo, "write-tree")

	response, err := (RollbackService{
		RepoRoot: repo, ArtifactRoot: artifactRoot,
	}).Run(context.Background(), RollbackRequest{
		ActivePatchID: "patch-1", TargetTransactionID: result.TransactionID,
		RollbackClass: RollbackIndexOnly,
	})
	if err != nil {
		t.Fatal(err)
	}
	if response.State != StateRollbackPartial || !response.Recovery.ManualRequired {
		t.Fatalf("response = %#v", response)
	}
	if after := runGitOutput(t, repo, "write-tree"); after != beforeRollback {
		t.Fatal("manual-required rollback changed the index")
	}
}

func TestRollbackRejectsClassNotDeclaredByEvidence(t *testing.T) {
	repo := initStageRepository(t)
	artifactRoot := filepath.Join(repo, ".git", "git-mcp-transactions")
	writeFile(t, repo, "selected.txt", "selected change\n")
	request, err := NewStageTransactionRequest(gitStageBackend{}, StageRequest{
		ActivePatchID: "patch-1", Paths: []string{"selected.txt"},
	})
	if err != nil {
		t.Fatal(err)
	}
	result, err := persistentRunner(repo, artifactRoot).Run(context.Background(), request)
	if err != nil {
		t.Fatal(err)
	}

	response, err := (RollbackService{
		RepoRoot: repo, ArtifactRoot: artifactRoot,
	}).Run(context.Background(), RollbackRequest{
		ActivePatchID: "patch-1", TargetTransactionID: result.TransactionID,
		RollbackClass: RollbackRefOnly,
	})
	if err == nil || response != nil {
		t.Fatalf("response=%#v err=%v", response, err)
	}
}

func persistentRunner(repo, artifactRoot string) *Runner {
	return NewRunner(
		LocalRepository(repo),
		GitObserver{StackRefPrefixes: []string{"refs/heads", "refs/stack"}},
		GitSnapshotStore{},
		&JSONLJournalStore{Root: artifactRoot},
		Dispatcher{Handlers: map[RollbackClass]RollbackHandler{
			RollbackIndexOnly: IndexSnapshotRollback{},
			RollbackRefOnly:   FinalizePatchRollback{},
		}},
		DirectoryEvidenceEmitter{Root: artifactRoot, SealPostflight: true},
	)
}

func stringsTrimFileURI(value string) string {
	const prefix = "file://"
	if len(value) >= len(prefix) && value[:len(prefix)] == prefix {
		return value[len(prefix):]
	}
	return value
}
