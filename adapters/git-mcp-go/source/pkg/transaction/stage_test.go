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

type gitStageBackend struct {
	err error
}

func (b gitStageBackend) AddFiles(repoPath string, files []string) (string, error) {
	if b.err != nil {
		return "", b.err
	}
	command := exec.Command("git", append([]string{"add", "--"}, files...)...)
	command.Dir = repoPath
	output, err := command.CombinedOutput()
	return string(output), err
}

func TestStackStageRepositoryStates(t *testing.T) {
	tests := []struct {
		name  string
		setup func(*testing.T, string)
	}{
		{name: "clean"},
		{name: "dirty", setup: func(t *testing.T, repo string) {
			writeFile(t, repo, "other.txt", "dirty\n")
		}},
		{name: "partial", setup: func(t *testing.T, repo string) {
			writeFile(t, repo, "other.txt", "staged before transaction\n")
			runGit(t, repo, "add", "other.txt")
		}},
		{name: "untracked", setup: func(t *testing.T, repo string) {
			writeFile(t, repo, "untracked.txt", "preserve me\n")
		}},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			repo := initStageRepository(t)
			if test.setup != nil {
				test.setup(t, repo)
			}
			beforeFiles := worktreeFiles(t, repo)
			writeFile(t, repo, "selected.txt", "selected change\n")
			beforeFiles["selected.txt"] = "selected change\n"

			result := runStage(t, repo, StageRequest{
				ActivePatchID: "patch-1",
				Paths:         []string{"selected.txt"},
			}, gitStageBackend{})
			if !result.OK || result.State != StateCommitted {
				t.Fatalf("result = %#v", result)
			}
			stagedPaths, err := StagedPaths(context.Background(), LocalRepository(repo), result.Snapshot.IndexTreeOID)
			assertStringSlicesEqual(t, stagedPaths, err, []string{"selected.txt"})
			if afterFiles := worktreeFiles(t, repo); !mapsEqual(beforeFiles, afterFiles) {
				t.Fatalf("worktree changed: before=%v after=%v", beforeFiles, afterFiles)
			}
			assertEvidenceKinds(t, result.Evidence, "transaction", "snapshot", "journal", "postflight")
		})
	}
}

func TestStackStageHunkSelection(t *testing.T) {
	repo := initStageRepository(t)
	writeFile(t, repo, "selected.txt", "line one changed\nline two\n")
	patch := runGitOutput(t, repo, "diff", "--", "selected.txt")

	result := runStage(t, repo, StageRequest{
		ActivePatchID: "patch-1",
		Paths:         []string{"selected.txt"},
		HunkPatch:     patch,
	}, gitStageBackend{})
	if !result.OK {
		t.Fatalf("result = %#v", result)
	}
	if staged := runGitOutput(t, repo, "diff", "--cached", "--name-only"); staged != "selected.txt" {
		t.Fatalf("staged paths = %q", staged)
	}
	if content := readFile(t, repo, "selected.txt"); content != "line one changed\nline two\n" {
		t.Fatalf("worktree content = %q", content)
	}
}

func TestStackStageMutationFailureRestoresIndex(t *testing.T) {
	repo := initStageRepository(t)
	writeFile(t, repo, "other.txt", "staged before transaction\n")
	runGit(t, repo, "add", "other.txt")
	before := runGitOutput(t, repo, "write-tree")
	writeFile(t, repo, "selected.txt", "selected change\n")

	request, err := NewStageTransactionRequest(gitStageBackend{err: errors.New("injected stage failure")}, StageRequest{
		ActivePatchID: "patch-1",
		Paths:         []string{"selected.txt"},
	})
	if err != nil {
		t.Fatal(err)
	}
	runner := stageRunner(repo)
	result, err := runner.Run(context.Background(), request)
	if err == nil {
		t.Fatal("Run() error = nil")
	}
	if result.State != StateRolledBack || result.RollbackClass != RollbackIndexOnly {
		t.Fatalf("result = %#v", result)
	}
	if after := runGitOutput(t, repo, "write-tree"); after != before {
		t.Fatalf("index tree = %s, want %s", after, before)
	}
	assertEvidenceKinds(t, result.Evidence, "rollback", "diagnostic")
}

func TestStackStageRejectsPathspecPatterns(t *testing.T) {
	_, err := NewStageTransactionRequest(gitStageBackend{}, StageRequest{
		ActivePatchID: "patch-1",
		Paths:         []string{"*.txt"},
	})
	if err == nil {
		t.Fatal("NewStageTransactionRequest() error = nil")
	}
}

func runStage(t *testing.T, repo string, request StageRequest, backend StageBackend) *Result {
	t.Helper()
	transactionRequest, err := NewStageTransactionRequest(backend, request)
	if err != nil {
		t.Fatal(err)
	}
	result, err := stageRunner(repo).Run(context.Background(), transactionRequest)
	if err != nil {
		t.Fatalf("Run() error = %v, result = %#v", err, result)
	}
	return result
}

func stageRunner(repo string) *Runner {
	return NewRunner(
		LocalRepository(repo),
		GitObserver{StackRefPrefixes: []string{"refs/heads", "refs/stack"}},
		GitSnapshotStore{},
		NewMemoryJournalStore(),
		Dispatcher{Handlers: map[RollbackClass]RollbackHandler{
			RollbackIndexOnly: IndexSnapshotRollback{},
		}},
		URIEmitter{},
	)
}

func initStageRepository(t *testing.T) string {
	t.Helper()
	repo := t.TempDir()
	runGit(t, repo, "init")
	runGit(t, repo, "config", "user.name", "Test User")
	runGit(t, repo, "config", "user.email", "test@example.com")
	writeFile(t, repo, "selected.txt", "line one\nline two\n")
	writeFile(t, repo, "other.txt", "other\n")
	runGit(t, repo, "add", "selected.txt", "other.txt")
	runGit(t, repo, "commit", "-m", "initial")
	return repo
}

func writeFile(t *testing.T, repo, name, content string) {
	t.Helper()
	path := filepath.Join(repo, name)
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}

func readFile(t *testing.T, repo, name string) string {
	t.Helper()
	content, err := os.ReadFile(filepath.Join(repo, name))
	if err != nil {
		t.Fatal(err)
	}
	return string(content)
}

func worktreeFiles(t *testing.T, repo string) map[string]string {
	t.Helper()
	result := map[string]string{}
	entries, err := os.ReadDir(repo)
	if err != nil {
		t.Fatal(err)
	}
	for _, entry := range entries {
		if entry.IsDir() || entry.Name() == ".git" {
			continue
		}
		result[entry.Name()] = readFile(t, repo, entry.Name())
	}
	return result
}

func mapsEqual(left, right map[string]string) bool {
	if len(left) != len(right) {
		return false
	}
	for key, value := range left {
		if right[key] != value {
			return false
		}
	}
	return true
}

func assertStringSlicesEqual(t *testing.T, actual []string, err error, expected []string) {
	t.Helper()
	if err != nil {
		t.Fatal(err)
	}
	if strings.Join(actual, "\x00") != strings.Join(expected, "\x00") {
		t.Fatalf("values = %v, want %v", actual, expected)
	}
}

func runGitOutput(t *testing.T, repo string, args ...string) string {
	t.Helper()
	command := exec.Command("git", args...)
	command.Dir = repo
	output, err := command.CombinedOutput()
	if err != nil {
		t.Fatalf("git %s: %v\n%s", strings.Join(args, " "), err, output)
	}
	return strings.TrimSpace(string(output))
}
