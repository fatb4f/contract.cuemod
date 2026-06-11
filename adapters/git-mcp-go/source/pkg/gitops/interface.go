package gitops

// GitOperations defines the interface for Git operations
type GitOperations interface {
	GetStatus(repoPath string) (string, error)
	GetDiffUnstaged(repoPath string) (string, error)
	GetDiffStaged(repoPath string) (string, error)
	GetDiff(repoPath string, target string) (string, error)
	CommitChanges(repoPath string, message string) (string, error)
	AmendCommit(repoPath string, message string, noEdit bool) (string, error)
	CherryPick(repoPath string, revision string) (string, error)
	RevertCommit(repoPath string, revision string, noCommit bool) (string, error)
	AddFiles(repoPath string, files []string) (string, error)
	ResetStaged(repoPath string) (string, error)
	GetLog(repoPath string, maxCount int) ([]string, error)
	CreateBranch(repoPath string, branchName string, baseBranch string) (string, error)
	CheckoutBranch(repoPath string, branchName string) (string, error)
	InitRepo(repoPath string) (string, error)
	ShowCommit(repoPath string, revision string) (string, error)
	PushChanges(repoPath string, remote string, branch string) (string, error)
	ListWorktrees(repoPath string) (string, error)
	AddWorktree(repoPath string, worktreePath string, branch string, commit string, detach bool) (string, error)
	RemoveWorktree(repoPath string, worktreePath string, force bool) (string, error)
	PruneWorktrees(repoPath string) (string, error)
}
