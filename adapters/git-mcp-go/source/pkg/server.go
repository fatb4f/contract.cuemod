package pkg

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/geropl/git-mcp-go/pkg/gitops"
	"github.com/geropl/git-mcp-go/pkg/transaction"
	"github.com/mark3labs/mcp-go/mcp"
	"github.com/mark3labs/mcp-go/server"
)

// GitServer represents the Git MCP server
type GitServer struct {
	server      *server.MCPServer
	repoPaths   []string // Changed from single string to array of strings
	gitOps      gitops.GitOperations
	writeAccess bool
	cue         *cueAdapter
}

// NewGitServer creates a new Git MCP server
func NewGitServer(repoPaths []string, gitOps gitops.GitOperations, writeAccess bool) *GitServer {
	s := server.NewMCPServer(
		"Git MCP Server",
		"1.3.1",
	)

	// Normalize repository paths
	normalizedPaths := make([]string, 0, len(repoPaths))
	for _, path := range repoPaths {
		if path == "" {
			continue
		}

		absPath, err := filepath.Abs(path)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Warning: failed to resolve path %s: %v\n", path, err)
			continue
		}

		if isGitRepository(absPath) {
			normalizedPaths = append(normalizedPaths, absPath)
		} else {
			fmt.Fprintf(os.Stderr, "Warning: not a git repository: %s\n", absPath)
		}
	}

	return &GitServer{
		server:      s,
		repoPaths:   normalizedPaths,
		gitOps:      gitOps,
		writeAccess: writeAccess,
		cue:         newCueAdapter(),
	}
}

func isGitRepository(path string) bool {
	cmd := exec.Command("git", "-C", path, "rev-parse", "--is-inside-work-tree")
	output, err := cmd.Output()
	if err == nil && strings.TrimSpace(string(output)) == "true" {
		return true
	}

	gitPath := filepath.Join(path, ".git")
	if info, err := os.Stat(gitPath); err == nil {
		return info.IsDir() || info.Mode().IsRegular()
	}
	return false
}

// isPathInAllowedRepos checks if a path is within any of the allowed repositories
func (s *GitServer) isPathInAllowedRepos(path string) bool {
	// Ensure path is absolute and clean
	absPath, err := filepath.Abs(path)
	if err != nil {
		return false
	}
	absPath = filepath.Clean(absPath)

	// Check if the path is within any of the allowed repositories
	for _, repoPath := range s.repoPaths {
		allowedPath, err := filepath.Abs(repoPath)
		if err != nil {
			continue
		}
		allowedPath = filepath.Clean(allowedPath)
		if absPath == allowedPath {
			return true
		}
		rel, err := filepath.Rel(allowedPath, absPath)
		if err == nil && rel != ".." && !strings.HasPrefix(rel, ".."+string(filepath.Separator)) {
			return true
		}
	}
	return false
}

// validateRepoPath validates and normalizes a repository path
func (s *GitServer) validateRepoPath(requestedPath string) (string, error) {
	// If no specific path is provided, but we have repositories configured
	if requestedPath == "" {
		if len(s.repoPaths) > 0 {
			// Use the first repository as default
			return s.repoPaths[0], nil
		}
		return "", fmt.Errorf("no repository specified and no defaults configured")
	}

	// Always convert to absolute path first
	absPath, err := filepath.Abs(requestedPath)
	if err != nil {
		return "", fmt.Errorf("invalid path: %w", err)
	}

	// Check if path is within allowed repositories
	if !s.isPathInAllowedRepos(absPath) {
		return "", fmt.Errorf(
			"access denied - path outside allowed repositories: %s",
			absPath,
		)
	}

	if !isGitRepository(absPath) {
		return "", fmt.Errorf("not a git repository: %s", absPath)
	}

	return absPath, nil
}

// getRepoPathForOperation determines which repo path to use for an operation
func (s *GitServer) getRepoPathForOperation(requestedPath string) (string, error) {
	return s.validateRepoPath(requestedPath)
}

func GetReadOnlyToolNames() map[string]bool {
	return map[string]bool{
		"git_status":              true,
		"git_diff_unstaged":       true,
		"git_diff_staged":         true,
		"git_diff":                true,
		"git_log":                 true,
		"git_show":                true,
		"git_worktree_list":       true,
		"cue_eval":                true,
		"cue_validate":            true,
		"cue_symbol_resolve":      true,
		"cue_symbol_references":   true,
		"cue_diagnostics":         true,
		"ralph_runtime_preflight": true,
		"ralph_git_mcp_allowlist": true,
		"ralph_surface_resolve":   true,
		"ralph_surface_preflight": true,
	}
}

func GetLocalOnlyToolNames() map[string]bool {
	// local tools that alter state, complementing the read-only tools
	result := map[string]bool{
		"git_init":             true,
		"git_create_branch":    true,
		"git_checkout":         true,
		"git_commit":           true,
		"git_commit_amend":     true,
		"git_cherry_pick":      true,
		"git_revert":           true,
		"git_add":              true,
		"git_reset":            true,
		"stack_stage":          true,
		"stack_finalize_patch": true,
		"git_worktree_add":     true,
		"git_worktree_remove":  true,
		"git_worktree_prune":   true,
	}

	for toolName := range GetReadOnlyToolNames() {
		result[toolName] = true
	}
	return result
}

// RegisterTools registers all Git tools with the MCP server
func (s *GitServer) RegisterTools() {
	s.registerCueTools()

	// Register git_status tool
	var repoPathDesc string

	if len(s.repoPaths) == 0 {
		repoPathDesc = "Path to Git repository"
		s.server.AddTool(mcp.NewTool("git_status",
			mcp.WithDescription("Shows the working tree status"),
			mcp.WithString("repo_path",
				mcp.Required(),
				mcp.Description(repoPathDesc),
			),
		), s.gitStatusHandler)
	} else {
		defaultRepo := s.repoPaths[0]
		if len(s.repoPaths) == 1 {
			repoPathDesc = fmt.Sprintf("Path to Git repository (default: %s)", defaultRepo)
		} else {
			repoPathDesc = fmt.Sprintf("Path to Git repository (default: %s, %d repositories available)", defaultRepo, len(s.repoPaths))
		}
		s.server.AddTool(mcp.NewTool("git_status",
			mcp.WithDescription("Shows the working tree status"),
			mcp.WithString("repo_path",
				mcp.Description(repoPathDesc),
			),
		), s.gitStatusHandler)
	}

	// Register git_diff_unstaged tool
	if len(s.repoPaths) == 0 {
		s.server.AddTool(mcp.NewTool("git_diff_unstaged",
			mcp.WithDescription("Shows changes in the working directory that are not yet staged"),
			mcp.WithString("repo_path",
				mcp.Required(),
				mcp.Description(repoPathDesc),
			),
		), s.gitDiffUnstagedHandler)
	} else {
		s.server.AddTool(mcp.NewTool("git_diff_unstaged",
			mcp.WithDescription("Shows changes in the working directory that are not yet staged"),
			mcp.WithString("repo_path",
				mcp.Description(repoPathDesc),
			),
		), s.gitDiffUnstagedHandler)
	}

	// Register git_diff_staged tool
	if len(s.repoPaths) == 0 {
		s.server.AddTool(mcp.NewTool("git_diff_staged",
			mcp.WithDescription("Shows changes that are staged for commit"),
			mcp.WithString("repo_path",
				mcp.Required(),
				mcp.Description(repoPathDesc),
			),
		), s.gitDiffStagedHandler)
	} else {
		s.server.AddTool(mcp.NewTool("git_diff_staged",
			mcp.WithDescription("Shows changes that are staged for commit"),
			mcp.WithString("repo_path",
				mcp.Description(repoPathDesc),
			),
		), s.gitDiffStagedHandler)
	}

	// Register git_diff tool
	diffTool := mcp.NewTool("git_diff",
		mcp.WithDescription("Shows differences between branches or commits"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to Git repository"),
		),
		mcp.WithString("target",
			mcp.Required(),
			mcp.Description("Target branch or commit to compare with"),
		),
	)
	s.server.AddTool(diffTool, s.gitDiffHandler)

	// Register git_commit tool
	commitTool := mcp.NewTool("git_commit",
		mcp.WithDescription("Records changes to the repository"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to Git repository"),
		),
		mcp.WithString("message",
			mcp.Required(),
			mcp.Description("Commit message"),
		),
	)
	s.server.AddTool(commitTool, s.gitCommitHandler)

	// Register git_commit_amend tool
	commitAmendTool := mcp.NewTool("git_commit_amend",
		mcp.WithDescription("Amends the most recent commit"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to Git repository"),
		),
		mcp.WithString("message",
			mcp.Description("Replacement commit message"),
		),
		mcp.WithBoolean("no_edit",
			mcp.Description("Reuse the previous commit message"),
		),
	)
	s.server.AddTool(commitAmendTool, s.gitCommitAmendHandler)

	// Register git_cherry_pick tool
	cherryPickTool := mcp.NewTool("git_cherry_pick",
		mcp.WithDescription("Applies the changes introduced by an existing commit"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to Git repository"),
		),
		mcp.WithString("revision",
			mcp.Required(),
			mcp.Description("Commit hash, branch name, or tag to cherry-pick"),
		),
	)
	s.server.AddTool(cherryPickTool, s.gitCherryPickHandler)

	// Register git_revert tool
	revertTool := mcp.NewTool("git_revert",
		mcp.WithDescription("Reverts changes introduced by an existing commit"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to Git repository"),
		),
		mcp.WithString("revision",
			mcp.Required(),
			mcp.Description("Commit hash, branch name, or tag to revert"),
		),
		mcp.WithBoolean("no_commit",
			mcp.Description("Apply the revert without creating a commit"),
		),
	)
	s.server.AddTool(revertTool, s.gitRevertHandler)

	// Register git_add tool
	addTool := mcp.NewTool("git_add",
		mcp.WithDescription("Adds file contents to the staging area"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to Git repository"),
		),
		// Note: mcp-go doesn't have WithStringArray, so we'll use a string and parse it
		mcp.WithString("files",
			mcp.Required(),
			mcp.Description("Comma-separated list of file paths to stage"),
		),
	)
	s.server.AddTool(addTool, s.gitAddHandler)

	// Register git_reset tool
	resetTool := mcp.NewTool("git_reset",
		mcp.WithDescription("Unstages all staged changes"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to Git repository"),
		),
	)
	s.server.AddTool(resetTool, s.gitResetHandler)

	stackStageTool := mcp.NewTool("stack_stage",
		mcp.WithDescription("Stages selected paths or hunks through the stack transaction runner"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to Git repository"),
		),
		mcp.WithString("active_patch_id",
			mcp.Required(),
			mcp.Description("Stable identity of the active patch"),
		),
		mcp.WithString("paths",
			mcp.Required(),
			mcp.Description("Comma-separated exact repository-relative paths"),
		),
		mcp.WithString("hunk_patch",
			mcp.Description("Optional unified patch to apply to the index only"),
		),
	)
	s.server.AddTool(stackStageTool, s.stackStageHandler)

	stackFinalizePatchTool := mcp.NewTool("stack_finalize_patch",
		mcp.WithDescription("Creates a patch commit and stack ref through the transaction runner"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to Git repository"),
		),
		mcp.WithString("patch_id",
			mcp.Required(),
			mcp.Description("Stable patch identity"),
		),
		mcp.WithString("message",
			mcp.Required(),
			mcp.Description("Patch commit message"),
		),
		mcp.WithString("prepared_evidence_uri",
			mcp.Required(),
			mcp.Description("Prepared evidence bound to the staged tree"),
		),
		mcp.WithString("prepared_tree_oid",
			mcp.Required(),
			mcp.Description("Tree object identity recorded by prepared evidence"),
		),
	)
	s.server.AddTool(stackFinalizePatchTool, s.stackFinalizePatchHandler)

	// Register git_log tool
	logTool := mcp.NewTool("git_log",
		mcp.WithDescription("Shows the commit logs"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to Git repository"),
		),
		mcp.WithNumber("max_count",
			mcp.Description("Maximum number of commits to show (default: 10)"),
		),
	)
	s.server.AddTool(logTool, s.gitLogHandler)

	// Register git_create_branch tool
	createBranchTool := mcp.NewTool("git_create_branch",
		mcp.WithDescription("Creates a new branch from an optional base branch"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to Git repository"),
		),
		mcp.WithString("branch_name",
			mcp.Required(),
			mcp.Description("Name of the new branch"),
		),
		mcp.WithString("base_branch",
			mcp.Description("Starting point for the new branch"),
		),
	)
	s.server.AddTool(createBranchTool, s.gitCreateBranchHandler)

	// Register git_checkout tool
	checkoutTool := mcp.NewTool("git_checkout",
		mcp.WithDescription("Switches branches"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to Git repository"),
		),
		mcp.WithString("branch_name",
			mcp.Required(),
			mcp.Description("Name of branch to checkout"),
		),
	)
	s.server.AddTool(checkoutTool, s.gitCheckoutHandler)

	// Register git_show tool
	showTool := mcp.NewTool("git_show",
		mcp.WithDescription("Shows the contents of a commit"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to Git repository"),
		),
		mcp.WithString("revision",
			mcp.Required(),
			mcp.Description("The revision (commit hash, branch name, tag) to show"),
		),
	)
	s.server.AddTool(showTool, s.gitShowHandler)

	// Register git_init tool
	initTool := mcp.NewTool("git_init",
		mcp.WithDescription("Initialize a new Git repository"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to directory to initialize git repo"),
		),
	)
	s.server.AddTool(initTool, s.gitInitHandler)

	// Register git_worktree_list tool
	worktreeListTool := mcp.NewTool("git_worktree_list",
		mcp.WithDescription("Lists linked worktrees in porcelain format"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to Git repository"),
		),
	)
	s.server.AddTool(worktreeListTool, s.gitWorktreeListHandler)

	// Register git_worktree_add tool
	worktreeAddTool := mcp.NewTool("git_worktree_add",
		mcp.WithDescription("Adds a linked worktree"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to Git repository"),
		),
		mcp.WithString("path",
			mcp.Required(),
			mcp.Description("Path for the new worktree"),
		),
		mcp.WithString("branch",
			mcp.Description("Branch to create for the new worktree"),
		),
		mcp.WithString("commit",
			mcp.Description("Commit or branch to check out"),
		),
		mcp.WithBoolean("detach",
			mcp.Description("Check out the worktree in detached HEAD mode"),
		),
	)
	s.server.AddTool(worktreeAddTool, s.gitWorktreeAddHandler)

	// Register git_worktree_remove tool
	worktreeRemoveTool := mcp.NewTool("git_worktree_remove",
		mcp.WithDescription("Removes a linked worktree"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to Git repository"),
		),
		mcp.WithString("path",
			mcp.Required(),
			mcp.Description("Path to the worktree to remove"),
		),
		mcp.WithBoolean("force",
			mcp.Description("Force removal of the worktree"),
		),
	)
	s.server.AddTool(worktreeRemoveTool, s.gitWorktreeRemoveHandler)

	// Register git_worktree_prune tool
	worktreePruneTool := mcp.NewTool("git_worktree_prune",
		mcp.WithDescription("Prunes stale worktree administrative files"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to Git repository"),
		),
	)
	s.server.AddTool(worktreePruneTool, s.gitWorktreePruneHandler)

	// Register git_list_repositories tool
	s.server.AddTool(mcp.NewTool("git_list_repositories",
		mcp.WithDescription("Lists all available Git repositories"),
	), s.gitListRepositoriesHandler)

	if s.writeAccess {
		// Register git_push tool
		pushTool := mcp.NewTool("git_push",
			mcp.WithDescription("Pushes local commits to a remote repository (requires --write-access flag)"),
			mcp.WithString("repo_path",
				mcp.Required(),
				mcp.Description("Path to Git repository"),
			),
			mcp.WithString("remote",
				mcp.Description("Remote name (default: origin)"),
			),
			mcp.WithString("branch",
				mcp.Description("Branch name to push (default: current branch)"),
			),
		)
		s.server.AddTool(pushTool, s.gitPushHandler)
	}
}

// Serve starts the MCP server
func (s *GitServer) Serve() error {
	return server.ServeStdio(s.server)
}

// Tool handlers

func (s *GitServer) gitStatusHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)

	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}

	status, err := s.gitOps.GetStatus(repoPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to get status: %v", err)), nil
	}

	return mcp.NewToolResultText(fmt.Sprintf("Repository status for %s:\n%s", repoPath, status)), nil
}

func (s *GitServer) gitDiffUnstagedHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)

	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}

	diff, err := s.gitOps.GetDiffUnstaged(repoPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to get unstaged diff: %v", err)), nil
	}

	return mcp.NewToolResultText(fmt.Sprintf("Unstaged changes for %s:\n%s", repoPath, diff)), nil
}

func (s *GitServer) gitDiffStagedHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)

	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}

	diff, err := s.gitOps.GetDiffStaged(repoPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to get staged diff: %v", err)), nil
	}

	return mcp.NewToolResultText(fmt.Sprintf("Staged changes for %s:\n%s", repoPath, diff)), nil
}

func (s *GitServer) gitDiffHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)

	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}

	target, ok := request.Params.Arguments["target"].(string)
	if !ok {
		return mcp.NewToolResultError("target must be a string"), nil
	}

	diff, err := s.gitOps.GetDiff(repoPath, target)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to get diff: %v", err)), nil
	}

	return mcp.NewToolResultText(fmt.Sprintf("Diff with %s for %s:\n%s", target, repoPath, diff)), nil
}

func (s *GitServer) gitCommitHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)

	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}

	message, ok := request.Params.Arguments["message"].(string)
	if !ok {
		return mcp.NewToolResultError("message must be a string"), nil
	}

	result, err := s.gitOps.CommitChanges(repoPath, message)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to commit: %v", err)), nil
	}

	return mcp.NewToolResultText(result), nil
}

func (s *GitServer) gitCommitAmendHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)

	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}

	message := ""
	if messageInterface, ok := request.Params.Arguments["message"]; ok {
		if messageStr, ok := messageInterface.(string); ok {
			message = messageStr
		}
	}

	noEdit := false
	if noEditInterface, ok := request.Params.Arguments["no_edit"]; ok {
		if noEditBool, ok := noEditInterface.(bool); ok {
			noEdit = noEditBool
		}
	}

	result, err := s.gitOps.AmendCommit(repoPath, message, noEdit)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to amend commit: %v", err)), nil
	}

	return mcp.NewToolResultText(result), nil
}

func (s *GitServer) gitCherryPickHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)

	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}

	revision, ok := request.Params.Arguments["revision"].(string)
	if !ok {
		return mcp.NewToolResultError("revision must be a string"), nil
	}

	result, err := s.gitOps.CherryPick(repoPath, revision)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to cherry-pick commit: %v", err)), nil
	}

	return mcp.NewToolResultText(result), nil
}

func (s *GitServer) gitRevertHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)

	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}

	revision, ok := request.Params.Arguments["revision"].(string)
	if !ok {
		return mcp.NewToolResultError("revision must be a string"), nil
	}

	noCommit := false
	if noCommitInterface, ok := request.Params.Arguments["no_commit"]; ok {
		if noCommitBool, ok := noCommitInterface.(bool); ok {
			noCommit = noCommitBool
		}
	}

	result, err := s.gitOps.RevertCommit(repoPath, revision, noCommit)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to revert commit: %v", err)), nil
	}

	return mcp.NewToolResultText(result), nil
}

func (s *GitServer) gitAddHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)

	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}

	filesStr, ok := request.Params.Arguments["files"].(string)
	if !ok {
		return mcp.NewToolResultError("files must be a string"), nil
	}

	// Split the comma-separated list of files
	files := strings.Split(filesStr, ",")
	// Trim spaces from each file path
	for i, file := range files {
		files[i] = strings.TrimSpace(file)
	}

	result, err := s.gitOps.AddFiles(repoPath, files)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to add files: %v", err)), nil
	}

	return mcp.NewToolResultText(result), nil
}

func (s *GitServer) gitResetHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)

	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}

	result, err := s.gitOps.ResetStaged(repoPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to reset: %v", err)), nil
	}

	return mcp.NewToolResultText(result), nil
}

func (s *GitServer) stackStageHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)
	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}
	activePatchID, _ := request.Params.Arguments["active_patch_id"].(string)
	pathList, _ := request.Params.Arguments["paths"].(string)
	hunkPatch, _ := request.Params.Arguments["hunk_patch"].(string)

	stageRequest, err := transaction.NewStageTransactionRequest(s.gitOps, transaction.StageRequest{
		ActivePatchID: activePatchID,
		Paths:         splitCommaList(pathList),
		HunkPatch:     hunkPatch,
	})
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Invalid stack.stage request: %v", err)), nil
	}
	artifactRoot := filepath.Join(repoPath, ".git", "git-mcp-transactions")
	runner := transaction.NewRunner(
		transaction.LocalRepository(repoPath),
		transaction.GitObserver{StackRefPrefixes: []string{"refs/heads", "refs/stack"}},
		transaction.GitSnapshotStore{},
		&transaction.JSONLJournalStore{Root: artifactRoot},
		transaction.Dispatcher{Handlers: map[transaction.RollbackClass]transaction.RollbackHandler{
			transaction.RollbackIndexOnly: transaction.IndexSnapshotRollback{},
		}},
		transaction.DirectoryEvidenceEmitter{Root: artifactRoot},
	)
	result, runErr := runner.Run(ctx, stageRequest)
	if runErr != nil {
		encoded, _ := json.Marshal(result)
		return mcp.NewToolResultError(fmt.Sprintf("stack.stage failed: %v\n%s", runErr, encoded)), nil
	}
	stagedPaths, err := transaction.StagedPaths(ctx, transaction.LocalRepository(repoPath), result.Snapshot.IndexTreeOID)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Read staged paths: %v", err)), nil
	}
	encoded, err := json.Marshal(transaction.NewStageResponse(result, stagedPaths))
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Encode stack.stage response: %v", err)), nil
	}
	return mcp.NewToolResultText(string(encoded)), nil
}

func (s *GitServer) stackFinalizePatchHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)
	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}
	finalizeRequest := transaction.FinalizePatchRequest{}
	finalizeRequest.PatchID, _ = request.Params.Arguments["patch_id"].(string)
	finalizeRequest.Message, _ = request.Params.Arguments["message"].(string)
	finalizeRequest.PreparedEvidenceURI, _ = request.Params.Arguments["prepared_evidence_uri"].(string)
	finalizeRequest.PreparedTreeOID, _ = request.Params.Arguments["prepared_tree_oid"].(string)

	transactionRequest, outcome, err := transaction.NewFinalizePatchTransactionRequest(repoPath, finalizeRequest)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Invalid stack.finalizePatch request: %v", err)), nil
	}
	artifactRoot := filepath.Join(repoPath, ".git", "git-mcp-transactions")
	runner := transaction.NewRunner(
		transaction.LocalRepository(repoPath),
		transaction.GitObserver{StackRefPrefixes: []string{"refs/heads", "refs/stack"}},
		transaction.GitSnapshotStore{},
		&transaction.JSONLJournalStore{Root: artifactRoot},
		transaction.Dispatcher{Handlers: map[transaction.RollbackClass]transaction.RollbackHandler{
			transaction.RollbackRefOnly: transaction.FinalizePatchRollback{},
		}},
		transaction.DirectoryEvidenceEmitter{Root: artifactRoot},
	)
	result, runErr := runner.Run(ctx, transactionRequest)
	if runErr != nil {
		encoded, _ := json.Marshal(result)
		return mcp.NewToolResultError(fmt.Sprintf("stack.finalizePatch failed: %v\n%s", runErr, encoded)), nil
	}
	encoded, err := json.Marshal(transaction.NewFinalizePatchResponse(result, finalizeRequest, outcome))
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Encode stack.finalizePatch response: %v", err)), nil
	}
	return mcp.NewToolResultText(string(encoded)), nil
}

func splitCommaList(value string) []string {
	parts := strings.Split(value, ",")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		if trimmed := strings.TrimSpace(part); trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}

func (s *GitServer) gitLogHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)

	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}

	maxCount := 10
	if maxCountInterface, ok := request.Params.Arguments["max_count"]; ok {
		if maxCountFloat, ok := maxCountInterface.(float64); ok {
			maxCount = int(maxCountFloat)
		}
	}

	logs, err := s.gitOps.GetLog(repoPath, maxCount)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to get log: %v", err)), nil
	}

	return mcp.NewToolResultText(fmt.Sprintf("Commit history for %s:\n%s", repoPath, strings.Join(logs, "\n"))), nil
}

func (s *GitServer) gitCreateBranchHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)

	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}

	branchName, ok := request.Params.Arguments["branch_name"].(string)
	if !ok {
		return mcp.NewToolResultError("branch_name must be a string"), nil
	}

	baseBranch := ""
	if baseBranchInterface, ok := request.Params.Arguments["base_branch"]; ok {
		if baseBranchStr, ok := baseBranchInterface.(string); ok {
			baseBranch = baseBranchStr
		}
	}

	result, err := s.gitOps.CreateBranch(repoPath, branchName, baseBranch)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to create branch: %v", err)), nil
	}

	return mcp.NewToolResultText(result), nil
}

func (s *GitServer) gitCheckoutHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)

	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}

	branchName, ok := request.Params.Arguments["branch_name"].(string)
	if !ok {
		return mcp.NewToolResultError("branch_name must be a string"), nil
	}

	result, err := s.gitOps.CheckoutBranch(repoPath, branchName)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to checkout branch: %v", err)), nil
	}

	return mcp.NewToolResultText(result), nil
}

func (s *GitServer) gitShowHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)

	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}

	revision, ok := request.Params.Arguments["revision"].(string)
	if !ok {
		return mcp.NewToolResultError("revision must be a string"), nil
	}

	result, err := s.gitOps.ShowCommit(repoPath, revision)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to show commit: %v", err)), nil
	}

	return mcp.NewToolResultText(result), nil
}

func (s *GitServer) gitInitHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)

	// For init, we don't validate through getRepoPathForOperation since we're creating a new repo
	if requestedPath == "" {
		return mcp.NewToolResultError("repo_path must be specified for initialization"), nil
	}

	// Ensure the path is absolute
	absPath, err := filepath.Abs(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to get absolute path: %v", err)), nil
	}

	result, err := s.gitOps.InitRepo(absPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to initialize repository: %v", err)), nil
	}

	// Add the new repository to our list of managed repositories
	s.repoPaths = append(s.repoPaths, absPath)

	return mcp.NewToolResultText(result), nil
}

func (s *GitServer) gitPushHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	// Check if write access is enabled
	if !s.writeAccess {
		return mcp.NewToolResultError("Write access is disabled. Use --write-access flag to enable remote operations."), nil
	}

	requestedPath, _ := request.Params.Arguments["repo_path"].(string)

	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}

	remote := ""
	if remoteInterface, ok := request.Params.Arguments["remote"]; ok {
		if remoteStr, ok := remoteInterface.(string); ok {
			remote = remoteStr
		}
	}

	branch := ""
	if branchInterface, ok := request.Params.Arguments["branch"]; ok {
		if branchStr, ok := branchInterface.(string); ok {
			branch = branchStr
		}
	}

	result, err := s.gitOps.PushChanges(repoPath, remote, branch)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to push changes: %v", err)), nil
	}

	return mcp.NewToolResultText(result), nil
}

func (s *GitServer) gitWorktreeListHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)

	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}

	result, err := s.gitOps.ListWorktrees(repoPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to list worktrees: %v", err)), nil
	}

	return mcp.NewToolResultText(result), nil
}

func (s *GitServer) gitWorktreeAddHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)

	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}

	worktreePath, ok := request.Params.Arguments["path"].(string)
	if !ok {
		return mcp.NewToolResultError("path must be a string"), nil
	}

	branch := ""
	if branchInterface, ok := request.Params.Arguments["branch"]; ok {
		if branchStr, ok := branchInterface.(string); ok {
			branch = branchStr
		}
	}

	commit := ""
	if commitInterface, ok := request.Params.Arguments["commit"]; ok {
		if commitStr, ok := commitInterface.(string); ok {
			commit = commitStr
		}
	}

	detach := false
	if detachInterface, ok := request.Params.Arguments["detach"]; ok {
		if detachBool, ok := detachInterface.(bool); ok {
			detach = detachBool
		}
	}

	result, err := s.gitOps.AddWorktree(repoPath, worktreePath, branch, commit, detach)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to add worktree: %v", err)), nil
	}

	return mcp.NewToolResultText(result), nil
}

func (s *GitServer) gitWorktreeRemoveHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)

	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}

	worktreePath, ok := request.Params.Arguments["path"].(string)
	if !ok {
		return mcp.NewToolResultError("path must be a string"), nil
	}

	force := false
	if forceInterface, ok := request.Params.Arguments["force"]; ok {
		if forceBool, ok := forceInterface.(bool); ok {
			force = forceBool
		}
	}

	result, err := s.gitOps.RemoveWorktree(repoPath, worktreePath, force)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to remove worktree: %v", err)), nil
	}

	return mcp.NewToolResultText(result), nil
}

func (s *GitServer) gitWorktreePruneHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)

	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Repository path error: %v", err)), nil
	}

	result, err := s.gitOps.PruneWorktrees(repoPath)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("Failed to prune worktrees: %v", err)), nil
	}

	return mcp.NewToolResultText(result), nil
}

// gitListRepositoriesHandler lists all available repositories
func (s *GitServer) gitListRepositoriesHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	if len(s.repoPaths) == 0 {
		return mcp.NewToolResultText("No repositories configured"), nil
	}

	var result strings.Builder
	result.WriteString(fmt.Sprintf("Available repositories (%d):\n\n", len(s.repoPaths)))

	for i, repoPath := range s.repoPaths {
		// Get the repository name (last part of the path)
		repoName := filepath.Base(repoPath)
		result.WriteString(fmt.Sprintf("%d. %s (%s)\n", i+1, repoName, repoPath))
	}

	return mcp.NewToolResultText(result.String()), nil
}
