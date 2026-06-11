package transaction

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
)

type StageBackend interface {
	AddFiles(repoPath string, files []string) (string, error)
}

type StageRequest struct {
	ActivePatchID string   `json:"active_patch_id"`
	Paths         []string `json:"paths"`
	HunkPatch     string   `json:"hunk_patch,omitempty"`
}

type StageResponse struct {
	Transaction StageTransactionResponse `json:"transaction"`
	StagedPaths []string                 `json:"stagedPaths"`
}

type StageTransactionResponse struct {
	TransactionID string        `json:"transactionID"`
	Command       string        `json:"command"`
	State         State         `json:"state"`
	OK            bool          `json:"ok"`
	Evidence      []EvidenceRef `json:"evidence"`
}

func NewStageResponse(result *Result, paths []string) StageResponse {
	return StageResponse{
		Transaction: StageTransactionResponse{
			TransactionID: result.TransactionID,
			Command:       result.Command,
			State:         result.State,
			OK:            result.OK,
			Evidence:      result.Evidence,
		},
		StagedPaths: paths,
	}
}

func NewStageTransactionRequest(backend StageBackend, request StageRequest) (Request, error) {
	if backend == nil {
		return Request{}, errors.New("stage backend is required")
	}
	if strings.TrimSpace(request.ActivePatchID) == "" {
		return Request{}, errors.New("active_patch_id is required")
	}
	paths, err := normalizeStagePaths(request.Paths)
	if err != nil {
		return Request{}, err
	}
	request.Paths = paths
	operation, err := json.Marshal(request)
	if err != nil {
		return Request{}, fmt.Errorf("encode stage operation: %w", err)
	}
	return Request{
		Command:   "stack.stage",
		Mutation:  StageMutation{Backend: backend, Paths: paths, HunkPatch: request.HunkPatch},
		Validator: StageValidator{Paths: paths},
		Policy: Policy{
			RequiredSnapshots: []Surface{
				SurfaceHead, SurfaceRefs, SurfaceIndex, SurfaceWorktree,
				SurfaceUntracked, SurfaceOperationInput,
			},
			AllowedRollbackClasses: []RollbackClass{RollbackIndexOnly},
			UntrackedPolicy:        "preserve",
			OperationInput:         string(operation),
		},
	}, nil
}

type StageMutation struct {
	Backend   StageBackend
	Paths     []string
	HunkPatch string
}

func (m StageMutation) Name() string                { return "stage-selected-content" }
func (m StageMutation) AffectedSurfaces() []Surface { return []Surface{SurfaceIndex} }

func (m StageMutation) Apply(ctx context.Context, repo Repository) error {
	if m.HunkPatch == "" {
		if _, err := m.Backend.AddFiles(repo.Root(), m.Paths); err != nil {
			return fmt.Errorf("stage paths: %w", err)
		}
		return nil
	}
	command := exec.CommandContext(ctx, "git", "-C", repo.Root(), "apply", "--cached", "--whitespace=nowarn", "-")
	patch := m.HunkPatch
	if !strings.HasSuffix(patch, "\n") {
		patch += "\n"
	}
	command.Stdin = strings.NewReader(patch)
	if output, err := command.CombinedOutput(); err != nil {
		return fmt.Errorf("stage hunk patch: %w: %s", err, strings.TrimSpace(string(output)))
	}
	return nil
}

type StageValidator struct {
	Paths []string
}

func (StageValidator) Name() string { return "validate-staged-state" }

func (v StageValidator) Validate(ctx context.Context, repo Repository, tx View) error {
	snapshot := tx.Snapshot()
	if snapshot.IndexTreeOID == "" {
		return errors.New("index snapshot tree is missing")
	}
	worktree, err := git(ctx, repo.Root(), "diff", "HEAD", "--binary")
	if err != nil {
		return err
	}
	if worktree != snapshot.WorktreePatch {
		return errors.New("worktree changed while staging")
	}
	untracked, err := git(ctx, repo.Root(), "ls-files", "--others", "--exclude-standard")
	if err != nil {
		return err
	}
	if !slices.Equal(lines(untracked), snapshot.Untracked) {
		return errors.New("untracked files changed while staging")
	}
	changed, err := git(ctx, repo.Root(), "diff", "--cached", "--name-only", snapshot.IndexTreeOID, "--")
	if err != nil {
		return err
	}
	changedPaths := lines(changed)
	if len(changedPaths) == 0 {
		return errors.New("selected content produced no index change")
	}
	allowed := make(map[string]struct{}, len(v.Paths))
	for _, path := range v.Paths {
		allowed[filepath.ToSlash(path)] = struct{}{}
	}
	for _, path := range changedPaths {
		if _, ok := allowed[filepath.ToSlash(path)]; !ok {
			return fmt.Errorf("index changed outside selected paths: %s", path)
		}
	}
	return nil
}

type IndexSnapshotRollback struct{}

func (IndexSnapshotRollback) Restore(
	ctx context.Context,
	tx View,
	failure ClassifiedFailure,
) (*RecoveryReport, error) {
	if failure.RollbackClass != RollbackIndexOnly {
		return manualRecovery("index snapshot rollback only supports index_only recovery"), nil
	}
	tree := tx.Snapshot().IndexTreeOID
	if tree == "" {
		return manualRecovery("index snapshot tree is unavailable"), nil
	}
	if _, err := git(ctx, tx.Preflight().RepoRoot, "read-tree", tree); err != nil {
		return &RecoveryReport{
			State: StateRollbackFailed, ManualRequired: true,
			Notes: []string{fmt.Sprintf("restore index tree %s: %v", tree, err)},
		}, err
	}
	return &RecoveryReport{State: StateRolledBack, Recovered: true}, nil
}

func StagedPaths(ctx context.Context, repo Repository, tree string) ([]string, error) {
	changed, err := git(ctx, repo.Root(), "diff", "--cached", "--name-only", tree, "--")
	if err != nil {
		return nil, err
	}
	return lines(changed), nil
}

func normalizeStagePaths(paths []string) ([]string, error) {
	if len(paths) == 0 {
		return nil, errors.New("at least one exact repository-relative path is required")
	}
	seen := map[string]struct{}{}
	normalized := make([]string, 0, len(paths))
	for _, value := range paths {
		path := filepath.ToSlash(filepath.Clean(strings.TrimSpace(value)))
		if path == "" || path == "." || filepath.IsAbs(path) || path == ".." || strings.HasPrefix(path, "../") {
			return nil, fmt.Errorf("invalid repository-relative path %q", value)
		}
		if strings.ContainsAny(path, "*?[") {
			return nil, fmt.Errorf("pathspec patterns are not allowed: %q", value)
		}
		if _, ok := seen[path]; ok {
			continue
		}
		seen[path] = struct{}{}
		normalized = append(normalized, path)
	}
	slices.Sort(normalized)
	return normalized, nil
}
