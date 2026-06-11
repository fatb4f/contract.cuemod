package pkg

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/geropl/git-mcp-go/pkg/gitops"
	"github.com/geropl/git-mcp-go/pkg/gitops/gogit"
	"github.com/geropl/git-mcp-go/pkg/gitops/shell"
	"github.com/geropl/git-mcp-go/pkg/transaction"
	"github.com/mark3labs/mcp-go/mcp"
	"github.com/stretchr/testify/require"
)

// initRepos initializes a remote repo and creates a local clone
func initRepos(t *testing.T, remoteDir, localDir string) {
	// Initialize bare repository in remoteDir
	cmd := exec.Command("git", "init", "--bare")
	cmd.Dir = remoteDir
	require.NoError(t, cmd.Run())

	// Clone the remote repository to localDir
	cmd = exec.Command("git", "clone", remoteDir, localDir)
	require.NoError(t, cmd.Run())

	// Set up git config for the test
	cmd = exec.Command("git", "config", "user.name", "Test User")
	cmd.Dir = localDir
	require.NoError(t, cmd.Run())

	cmd = exec.Command("git", "config", "user.email", "test@example.com")
	cmd.Dir = localDir
	require.NoError(t, cmd.Run())
}

func TestStackStageHandlerRunsTransaction(t *testing.T) {
	for _, mode := range []string{"shell", "go-git"} {
		t.Run(mode, func(t *testing.T) {
			repoDir := t.TempDir()
			initRepoWithCommit(t, repoDir)
			require.NoError(t, os.WriteFile(filepath.Join(repoDir, "test.txt"), []byte("changed\n"), 0o644))

			gitServer := NewGitServer([]string{repoDir}, gitOperationsForMode(t, mode), false)
			gitServer.RegisterTools()
			request := mcp.CallToolRequest{}
			request.Params.Name = "stack_stage"
			request.Params.Arguments = map[string]interface{}{
				"repo_path":       repoDir,
				"active_patch_id": "patch-1",
				"paths":           "test.txt",
			}
			result, err := gitServer.stackStageHandler(context.Background(), request)
			responseText := callToolText(t, result, err)
			var response transaction.StageResponse
			require.NoError(t, json.Unmarshal([]byte(responseText), &response))
			require.True(t, response.Transaction.OK)
			require.Equal(t, transaction.StateCommitted, response.Transaction.State)
			require.Equal(t, []string{"test.txt"}, response.StagedPaths)
			require.NotEmpty(t, response.Transaction.Evidence)
			require.FileExists(t, filepath.Join(
				repoDir, ".git", "git-mcp-transactions",
				response.Transaction.TransactionID, "transaction.json",
			))
			require.Equal(t, "test.txt", gitOutput(t, repoDir, "diff", "--cached", "--name-only"))
			content, err := os.ReadFile(filepath.Join(repoDir, "test.txt"))
			require.NoError(t, err)
			require.Equal(t, "changed", strings.TrimSpace(string(content)))
		})
	}
}

// createCommit creates a file and commits it
func createCommit(t *testing.T, repoDir, filename, content, message string) {
	filePath := filepath.Join(repoDir, filename)
	require.NoError(t, os.WriteFile(filePath, []byte(content), 0644))

	cmd := exec.Command("git", "add", filename)
	cmd.Dir = repoDir
	require.NoError(t, cmd.Run())

	cmd = exec.Command("git", "commit", "-m", message)
	cmd.Dir = repoDir
	require.NoError(t, cmd.Run())
}

func initRepoWithCommit(t *testing.T, repoDir string) {
	cmd := exec.Command("git", "init")
	cmd.Dir = repoDir
	require.NoError(t, cmd.Run())

	cmd = exec.Command("git", "config", "user.name", "Test User")
	cmd.Dir = repoDir
	require.NoError(t, cmd.Run())

	cmd = exec.Command("git", "config", "user.email", "test@example.com")
	cmd.Dir = repoDir
	require.NoError(t, cmd.Run())

	createCommit(t, repoDir, "test.txt", "test content", "Initial commit")
}

func gitOutput(t *testing.T, repoDir string, args ...string) string {
	cmd := exec.Command("git", args...)
	cmd.Dir = repoDir
	output, err := cmd.Output()
	require.NoError(t, err)
	return strings.TrimSpace(string(output))
}

func callToolText(t *testing.T, result *mcp.CallToolResult, err error) string {
	require.NoError(t, err)
	require.NotNil(t, result)
	require.False(t, result.IsError)
	require.NotEmpty(t, result.Content)

	textContent, ok := mcp.AsTextContent(result.Content[0])
	require.True(t, ok)
	return textContent.Text
}

func gitOperationsForMode(t *testing.T, mode string) gitops.GitOperations {
	switch mode {
	case "shell":
		return shell.NewShellGitOperations()
	case "go-git":
		return gogit.NewGoGitOperations()
	default:
		t.Fatalf("unknown mode: %s", mode)
		return nil
	}
}

func TestGitOperations(t *testing.T) {
	// Test cases table
	testCases := []struct {
		name           string
		setupFunc      func(t *testing.T, remoteRepo, localRepo string)               // Setup repositories
		action         string                                                         // MCP action to run
		params         map[string]interface{}                                         // Parameters for the action
		expectedResult func(t *testing.T, result string, remoteDir string, err error) // Validation function
	}{
		{
			name: "basic_push",
			setupFunc: func(t *testing.T, remoteRepo, localRepo string) {
				initRepos(t, remoteRepo, localRepo)
				createCommit(t, localRepo, "test.txt", "test content", "Initial commit")

				// Get the current branch name
				cmd := exec.Command("git", "rev-parse", "--abbrev-ref", "HEAD")
				cmd.Dir = localRepo
				output, err := cmd.Output()
				require.NoError(t, err)
				branch := strings.TrimSpace(string(output))

				// Set the branch parameter
				t.Logf("Current branch: %s", branch)
			},
			action: "git_push",
			params: map[string]interface{}{
				"remote": "origin",
				// We'll use the current branch name from the repository
				// This will be determined at runtime
			},
			expectedResult: func(t *testing.T, result string, remoteDir string, err error) {
				require.NoError(t, err)
				require.Contains(t, result, "Successfully pushed")

				// Verify the commit exists in the remote repository
				cmd := exec.Command("git", "log", "--oneline")
				cmd.Dir = remoteDir
				output, err := cmd.Output()
				require.NoError(t, err)
				require.Contains(t, string(output), "Initial commit")
			},
		},
		{
			name: "push_multiple_commits",
			setupFunc: func(t *testing.T, remoteRepo, localRepo string) {
				initRepos(t, remoteRepo, localRepo)
				createCommit(t, localRepo, "file1.txt", "content 1", "First commit")
				createCommit(t, localRepo, "file2.txt", "content 2", "Second commit")
				createCommit(t, localRepo, "file3.txt", "content 3", "Third commit")
			},
			action: "git_push",
			params: map[string]interface{}{},
			expectedResult: func(t *testing.T, result string, remoteDir string, err error) {
				require.NoError(t, err)
				require.Contains(t, result, "Successfully pushed")

				// Verify all commits exist in the remote repository
				cmd := exec.Command("git", "log", "--oneline")
				cmd.Dir = remoteDir
				output, err := cmd.Output()
				require.NoError(t, err)
				require.Contains(t, string(output), "First commit")
				require.Contains(t, string(output), "Second commit")
				require.Contains(t, string(output), "Third commit")
			},
		},
		{
			name: "push_different_branch",
			setupFunc: func(t *testing.T, remoteRepo, localRepo string) {
				initRepos(t, remoteRepo, localRepo)
				createCommit(t, localRepo, "main.txt", "main content", "Main branch commit")

				// Create and switch to a new branch
				cmd := exec.Command("git", "checkout", "-b", "feature")
				cmd.Dir = localRepo
				require.NoError(t, cmd.Run())

				createCommit(t, localRepo, "feature.txt", "feature content", "Feature branch commit")
			},
			action: "git_push",
			params: map[string]interface{}{
				"remote": "origin",
				"branch": "feature",
			},
			expectedResult: func(t *testing.T, result string, remoteDir string, err error) {
				require.NoError(t, err)
				require.Contains(t, result, "Successfully pushed")

				// Verify the feature branch exists in the remote repository
				cmd := exec.Command("git", "ls-remote", "--heads", remoteDir)
				output, err := cmd.Output()
				require.NoError(t, err)
				require.Contains(t, string(output), "refs/heads/feature")

				// Create a temporary directory to check the remote branch
				tempDir := t.TempDir()

				// Clone the remote repository to the temp directory
				cmd = exec.Command("git", "clone", "--branch", "feature", remoteDir, tempDir)
				require.NoError(t, cmd.Run())

				// Verify the commit exists in the feature branch
				cmd = exec.Command("git", "log", "--oneline")
				cmd.Dir = tempDir
				output, err = cmd.Output()
				require.NoError(t, err)
				require.Contains(t, string(output), "Feature branch commit")
			},
		},
		{
			name: "push_no_changes",
			setupFunc: func(t *testing.T, remoteRepo, localRepo string) {
				initRepos(t, remoteRepo, localRepo)
				createCommit(t, localRepo, "test.txt", "test content", "Initial commit")

				// Get the current branch name
				cmd := exec.Command("git", "rev-parse", "--abbrev-ref", "HEAD")
				cmd.Dir = localRepo
				output, err := cmd.Output()
				require.NoError(t, err)
				branch := strings.TrimSpace(string(output))

				// Push the commit
				cmd = exec.Command("git", "push", "origin", branch)
				cmd.Dir = localRepo
				require.NoError(t, cmd.Run())
			},
			action: "git_push",
			params: map[string]interface{}{},
			expectedResult: func(t *testing.T, result string, remoteDir string, err error) {
				require.NoError(t, err)
				require.Contains(t, result, "up-to-date")
			},
		},
	}

	// Run each test case in both modes
	modes := []string{"shell", "go-git"}

	for _, mode := range modes {
		for _, tc := range testCases {
			t.Run(fmt.Sprintf("%s_%s", tc.name, mode), func(t *testing.T) {
				// Create temporary directories for repositories
				remoteDir := t.TempDir()
				localDir := t.TempDir()

				// Setup repositories
				tc.setupFunc(t, remoteDir, localDir)

				// Create appropriate GitOperations implementation based on mode
				var gitOps gitops.GitOperations
				if mode == "shell" {
					gitOps = shell.NewShellGitOperations()
				} else {
					gitOps = gogit.NewGoGitOperations()
				}

				// Create server with local repository
				server := NewGitServer([]string{localDir}, gitOps, true) // Enable write access for tests
				server.RegisterTools()

				// Execute the action and validate results
				var result *mcp.CallToolResult
				var err error

				// Copy the parameters and add the repo_path if not present
				params := make(map[string]interface{})
				for k, v := range tc.params {
					params[k] = v
				}
				if _, ok := params["repo_path"]; !ok {
					params["repo_path"] = localDir
				}

				switch tc.action {
				case "git_push":
					request := mcp.CallToolRequest{}
					request.Params.Name = "git_push"
					request.Params.Arguments = params
					result, err = server.gitPushHandler(context.Background(), request)
				// Add other actions as needed
				default:
					t.Fatalf("Unknown action: %s", tc.action)
				}

				// Validate the results
				if result != nil && len(result.Content) > 0 {
					text := ""
					if textContent, ok := mcp.AsTextContent(result.Content[0]); ok {
						text = textContent.Text
					}
					tc.expectedResult(t, text, remoteDir, err)
				} else {
					tc.expectedResult(t, "", remoteDir, err)
				}
			})
		}
	}
}

func TestGitCommitOperations(t *testing.T) {
	modes := []string{"shell", "go-git"}

	for _, mode := range modes {
		t.Run(mode+"_amend", func(t *testing.T) {
			repoDir := t.TempDir()
			initRepoWithCommit(t, repoDir)

			require.NoError(t, os.WriteFile(filepath.Join(repoDir, "amended.txt"), []byte("amended content"), 0644))
			require.NoError(t, exec.Command("git", "-C", repoDir, "add", "amended.txt").Run())

			gitOps := gitOperationsForMode(t, mode)
			server := NewGitServer([]string{repoDir}, gitOps, false)
			server.RegisterTools()

			request := mcp.CallToolRequest{}
			request.Params.Name = "git_commit_amend"
			request.Params.Arguments = map[string]interface{}{
				"repo_path": repoDir,
				"message":   "Amended commit",
			}

			result, err := server.gitCommitAmendHandler(context.Background(), request)
			callToolText(t, result, err)

			require.Equal(t, "Amended commit", gitOutput(t, repoDir, "log", "-1", "--pretty=%s"))
			require.Contains(t, gitOutput(t, repoDir, "show", "--stat", "--oneline", "HEAD"), "amended.txt")
		})

		t.Run(mode+"_cherry_pick", func(t *testing.T) {
			repoDir := t.TempDir()
			initRepoWithCommit(t, repoDir)

			require.NoError(t, exec.Command("git", "-C", repoDir, "checkout", "-b", "feature/cherry-pick").Run())
			createCommit(t, repoDir, "picked.txt", "picked content", "Picked commit")
			pickedRevision := gitOutput(t, repoDir, "rev-parse", "HEAD")
			require.NoError(t, exec.Command("git", "-C", repoDir, "checkout", "master").Run())

			gitOps := gitOperationsForMode(t, mode)
			server := NewGitServer([]string{repoDir}, gitOps, false)
			server.RegisterTools()

			request := mcp.CallToolRequest{}
			request.Params.Name = "git_cherry_pick"
			request.Params.Arguments = map[string]interface{}{
				"repo_path": repoDir,
				"revision":  pickedRevision,
			}

			result, err := server.gitCherryPickHandler(context.Background(), request)
			callToolText(t, result, err)

			require.FileExists(t, filepath.Join(repoDir, "picked.txt"))
			require.Equal(t, "Picked commit", gitOutput(t, repoDir, "log", "-1", "--pretty=%s"))
		})

		t.Run(mode+"_revert", func(t *testing.T) {
			repoDir := t.TempDir()
			initRepoWithCommit(t, repoDir)
			createCommit(t, repoDir, "reverted.txt", "reverted content", "Commit to revert")
			revertedRevision := gitOutput(t, repoDir, "rev-parse", "HEAD")

			gitOps := gitOperationsForMode(t, mode)
			server := NewGitServer([]string{repoDir}, gitOps, false)
			server.RegisterTools()

			request := mcp.CallToolRequest{}
			request.Params.Name = "git_revert"
			request.Params.Arguments = map[string]interface{}{
				"repo_path": repoDir,
				"revision":  revertedRevision,
			}

			result, err := server.gitRevertHandler(context.Background(), request)
			callToolText(t, result, err)

			_, err = os.Stat(filepath.Join(repoDir, "reverted.txt"))
			require.True(t, os.IsNotExist(err), "reverted file should be removed")
			require.Contains(t, gitOutput(t, repoDir, "log", "-1", "--pretty=%s"), "Revert")
		})
	}
}

func TestGitWorktreeOperations(t *testing.T) {
	modes := []string{"shell", "go-git"}

	for _, mode := range modes {
		t.Run(mode, func(t *testing.T) {
			repoDir := t.TempDir()
			initRepoWithCommit(t, repoDir)

			gitOps := gitOperationsForMode(t, mode)
			server := NewGitServer([]string{repoDir}, gitOps, false)
			server.RegisterTools()

			listRequest := mcp.CallToolRequest{}
			listRequest.Params.Name = "git_worktree_list"
			listRequest.Params.Arguments = map[string]interface{}{
				"repo_path": repoDir,
			}

			result, err := server.gitWorktreeListHandler(context.Background(), listRequest)
			listText := callToolText(t, result, err)
			require.Contains(t, listText, "worktree "+repoDir)
			require.Contains(t, listText, "HEAD ")

			worktreePath := filepath.Join(t.TempDir(), "repo-feature")
			addRequest := mcp.CallToolRequest{}
			addRequest.Params.Name = "git_worktree_add"
			addRequest.Params.Arguments = map[string]interface{}{
				"repo_path": repoDir,
				"path":      worktreePath,
				"branch":    "feature/worktree-test",
			}

			result, err = server.gitWorktreeAddHandler(context.Background(), addRequest)
			callToolText(t, result, err)
			require.DirExists(t, worktreePath)

			result, err = server.gitWorktreeListHandler(context.Background(), listRequest)
			listText = callToolText(t, result, err)
			require.Contains(t, listText, "worktree "+worktreePath)

			removeRequest := mcp.CallToolRequest{}
			removeRequest.Params.Name = "git_worktree_remove"
			removeRequest.Params.Arguments = map[string]interface{}{
				"repo_path": repoDir,
				"path":      worktreePath,
			}

			result, err = server.gitWorktreeRemoveHandler(context.Background(), removeRequest)
			callToolText(t, result, err)
			_, err = os.Stat(worktreePath)
			require.True(t, os.IsNotExist(err), "worktree path should be removed")

			result, err = server.gitWorktreeListHandler(context.Background(), listRequest)
			listText = callToolText(t, result, err)
			require.NotContains(t, listText, "worktree "+worktreePath)

			pruneRequest := mcp.CallToolRequest{}
			pruneRequest.Params.Name = "git_worktree_prune"
			pruneRequest.Params.Arguments = map[string]interface{}{
				"repo_path": repoDir,
			}

			result, err = server.gitWorktreePruneHandler(context.Background(), pruneRequest)
			callToolText(t, result, err)
		})
	}
}

func TestWorktreeToolClassifications(t *testing.T) {
	readOnlyTools := GetReadOnlyToolNames()
	require.True(t, readOnlyTools["git_worktree_list"])
	require.False(t, readOnlyTools["git_worktree_add"])
	require.False(t, readOnlyTools["git_worktree_remove"])
	require.False(t, readOnlyTools["git_worktree_prune"])
	require.False(t, readOnlyTools["git_commit_amend"])
	require.False(t, readOnlyTools["git_cherry_pick"])
	require.False(t, readOnlyTools["git_revert"])

	localOnlyTools := GetLocalOnlyToolNames()
	require.True(t, localOnlyTools["git_worktree_list"])
	require.True(t, localOnlyTools["git_worktree_add"])
	require.True(t, localOnlyTools["git_worktree_remove"])
	require.True(t, localOnlyTools["git_worktree_prune"])
	require.True(t, localOnlyTools["git_commit_amend"])
	require.True(t, localOnlyTools["git_cherry_pick"])
	require.True(t, localOnlyTools["git_revert"])
}

func TestLinkedWorktreeAdmission(t *testing.T) {
	modes := []string{"shell", "go-git"}

	for _, mode := range modes {
		t.Run(mode, func(t *testing.T) {
			repoDir := t.TempDir()
			initRepoWithCommit(t, repoDir)

			worktreePath := filepath.Join(t.TempDir(), "linked-worktree")
			cmd := exec.Command("git", "worktree", "add", "-b", "linked/admission-test", worktreePath)
			cmd.Dir = repoDir
			require.NoError(t, cmd.Run())

			gitFile := filepath.Join(worktreePath, ".git")
			info, err := os.Stat(gitFile)
			require.NoError(t, err)
			require.True(t, info.Mode().IsRegular())

			gitOps := gitOperationsForMode(t, mode)
			server := NewGitServer([]string{worktreePath}, gitOps, false)
			server.RegisterTools()
			require.Equal(t, []string{worktreePath}, server.repoPaths)

			statusRequest := mcp.CallToolRequest{}
			statusRequest.Params.Name = "git_status"
			statusRequest.Params.Arguments = map[string]interface{}{
				"repo_path": worktreePath,
			}

			result, err := server.gitStatusHandler(context.Background(), statusRequest)
			statusText := callToolText(t, result, err)
			require.Contains(t, statusText, worktreePath)
		})
	}
}
