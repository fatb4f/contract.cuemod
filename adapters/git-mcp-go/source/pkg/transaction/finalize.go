package transaction

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"slices"
	"strings"
)

var patchIDPattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._-]*$`)

type FinalizePatchRequest struct {
	PatchID             string `json:"patchID"`
	Message             string `json:"message"`
	PreparedEvidenceURI string `json:"preparedEvidenceURI"`
	PreparedTreeOID     string `json:"preparedTreeOID"`
}

type FinalizePatchResponse struct {
	Transaction StageTransactionResponse `json:"transaction"`
	PatchID     string                   `json:"patchID"`
	CommitOID   string                   `json:"commitOID"`
	StackRef    string                   `json:"stackRef"`
	MetadataURI string                   `json:"metadataURI"`
}

type PatchMetadata struct {
	PatchID             string `json:"patchID"`
	CommitOID           string `json:"commitOID"`
	TreeOID             string `json:"treeOID"`
	ParentOID           string `json:"parentOID"`
	StackRef            string `json:"stackRef"`
	PreparedEvidenceURI string `json:"preparedEvidenceURI"`
	PreparedTreeOID     string `json:"preparedTreeOID"`
	EvidenceState       string `json:"evidenceState"`
}

type FinalizeOutcome struct {
	CommitOID   string
	TreeOID     string
	StackRef    string
	MetadataURI string
}

func NewFinalizePatchTransactionRequest(repoRoot string, request FinalizePatchRequest) (Request, *FinalizeOutcome, error) {
	if !patchIDPattern.MatchString(request.PatchID) {
		return Request{}, nil, fmt.Errorf("invalid patchID %q", request.PatchID)
	}
	if strings.TrimSpace(request.Message) == "" {
		return Request{}, nil, errors.New("message is required")
	}
	if strings.TrimSpace(request.PreparedEvidenceURI) == "" {
		return Request{}, nil, errors.New("preparedEvidenceURI is required")
	}
	if !oidPattern.MatchString(request.PreparedTreeOID) {
		return Request{}, nil, errors.New("preparedTreeOID must be a 40-character lowercase object ID")
	}
	stackRef := "refs/stack/patches/" + request.PatchID
	metadataPath := filepath.Join(repoRoot, ".git", "git-mcp-patches", request.PatchID+".json")
	operation, err := json.Marshal(request)
	if err != nil {
		return Request{}, nil, fmt.Errorf("encode finalize operation: %w", err)
	}
	outcome := &FinalizeOutcome{StackRef: stackRef, MetadataURI: "file://" + filepath.ToSlash(metadataPath)}
	return Request{
		Command:            "stack.finalizePatch",
		PreflightValidator: FinalizePreflight{PreparedTreeOID: request.PreparedTreeOID},
		Mutation: FinalizePatchMutation{
			Request: request, Outcome: outcome, MetadataPath: metadataPath,
		},
		Validator: FinalizePatchValidator{
			Request: request, Outcome: outcome, MetadataPath: metadataPath,
		},
		Policy: Policy{
			RequiredSnapshots: []Surface{
				SurfaceHead, SurfaceRefs, SurfaceIndex, SurfaceWorktree,
				SurfaceUntracked, SurfaceAdapterArtifacts, SurfaceOperationInput,
			},
			AllowedRollbackClasses: []RollbackClass{RollbackRefOnly},
			UntrackedPolicy:        "preserve",
			OperationInput:         string(operation),
			AdapterArtifactPaths:   []string{metadataPath},
		},
	}, outcome, nil
}

type FinalizePreflight struct {
	PreparedTreeOID string
}

func (v FinalizePreflight) ValidatePreflight(ctx context.Context, repo Repository, preflight Preflight) error {
	if !preflight.IndexDirty {
		return errors.New("cannot finalize an empty staged tree")
	}
	if preflight.WorktreeDirty {
		return errors.New("cannot finalize with unstaged worktree changes")
	}
	if preflight.ConflictStatePresent {
		return errors.New("cannot finalize while a conflict operation is active")
	}
	tree, err := git(ctx, repo.Root(), "write-tree")
	if err != nil {
		return fmt.Errorf("read staged tree: %w", err)
	}
	if tree != v.PreparedTreeOID {
		return errors.New("prepared evidence tree does not match the staged tree")
	}
	return nil
}

type FinalizePatchMutation struct {
	Request       FinalizePatchRequest
	Outcome       *FinalizeOutcome
	MetadataPath  string
	UpdateRef     func(context.Context, string, string, string, string) error
	WriteMetadata func(string, []byte) error
}

func (FinalizePatchMutation) Name() string { return "finalize-patch-object" }
func (FinalizePatchMutation) AffectedSurfaces() []Surface {
	return []Surface{SurfaceRefs, SurfaceAdapterArtifacts}
}

func (m FinalizePatchMutation) Apply(ctx context.Context, repo Repository) error {
	tree, err := git(ctx, repo.Root(), "write-tree")
	if err != nil {
		return fmt.Errorf("write staged tree: %w", err)
	}
	parent, err := git(ctx, repo.Root(), "rev-parse", "HEAD")
	if err != nil {
		return fmt.Errorf("read parent commit: %w", err)
	}
	commit, err := gitWithInput(ctx, repo.Root(), m.Request.Message+"\n", "commit-tree", tree, "-p", parent)
	if err != nil {
		return fmt.Errorf("create patch commit: %w", err)
	}
	oldOID := strings.Repeat("0", 40)
	if existing, refErr := git(ctx, repo.Root(), "rev-parse", "--verify", m.Outcome.StackRef); refErr == nil {
		oldOID = existing
	}
	updateRef := m.UpdateRef
	if updateRef == nil {
		updateRef = func(ctx context.Context, root, ref, newOID, previousOID string) error {
			_, err := git(ctx, root, "update-ref", ref, newOID, previousOID)
			return err
		}
	}
	if err := updateRef(ctx, repo.Root(), m.Outcome.StackRef, commit, oldOID); err != nil {
		return fmt.Errorf("update stack ref: %w", err)
	}
	metadata := PatchMetadata{
		PatchID: m.Request.PatchID, CommitOID: commit, TreeOID: tree, ParentOID: parent,
		StackRef: m.Outcome.StackRef, PreparedEvidenceURI: m.Request.PreparedEvidenceURI,
		PreparedTreeOID: m.Request.PreparedTreeOID, EvidenceState: "sealed",
	}
	encoded, err := json.MarshalIndent(metadata, "", "  ")
	if err != nil {
		return fmt.Errorf("encode patch metadata: %w", err)
	}
	writeMetadata := m.WriteMetadata
	if writeMetadata == nil {
		writeMetadata = writeAtomic
	}
	if err := writeMetadata(m.MetadataPath, append(encoded, '\n')); err != nil {
		return fmt.Errorf("write patch metadata: %w", err)
	}
	m.Outcome.CommitOID = commit
	m.Outcome.TreeOID = tree
	return nil
}

type FinalizePatchValidator struct {
	Request      FinalizePatchRequest
	Outcome      *FinalizeOutcome
	MetadataPath string
}

func (FinalizePatchValidator) Name() string { return "validate-finalized-patch" }

func (v FinalizePatchValidator) Validate(ctx context.Context, repo Repository, tx View) error {
	if v.Outcome.CommitOID == "" || v.Outcome.TreeOID == "" {
		return errors.New("finalize mutation did not report commit and tree identities")
	}
	if _, err := git(ctx, repo.Root(), "cat-file", "-e", v.Outcome.CommitOID+"^{commit}"); err != nil {
		return fmt.Errorf("patch commit does not exist: %w", err)
	}
	commitTree, err := git(ctx, repo.Root(), "show", "-s", "--format=%T", v.Outcome.CommitOID)
	if err != nil || commitTree != v.Outcome.TreeOID || commitTree != tx.Snapshot().IndexTreeOID {
		return errors.New("patch commit tree does not match the staged tree")
	}
	commitParent, err := git(ctx, repo.Root(), "show", "-s", "--format=%P", v.Outcome.CommitOID)
	if err != nil || commitParent != tx.Snapshot().HeadOID {
		return errors.New("patch commit parent does not match the preflight HEAD")
	}
	refOID, err := git(ctx, repo.Root(), "rev-parse", "--verify", v.Outcome.StackRef)
	if err != nil || refOID != v.Outcome.CommitOID {
		return fmt.Errorf("stack ref does not resolve to patch commit")
	}
	indexTree, err := git(ctx, repo.Root(), "write-tree")
	if err != nil || indexTree != tx.Snapshot().IndexTreeOID {
		return errors.New("index changed while finalizing patch")
	}
	worktree, err := git(ctx, repo.Root(), "diff", "HEAD", "--binary")
	if err != nil || worktree != tx.Snapshot().WorktreePatch {
		return errors.New("worktree changed while finalizing patch")
	}
	untracked, err := git(ctx, repo.Root(), "ls-files", "--others", "--exclude-standard")
	if err != nil || !slices.Equal(lines(untracked), tx.Snapshot().Untracked) {
		return errors.New("untracked files changed while finalizing patch")
	}
	content, err := os.ReadFile(v.MetadataPath)
	if err != nil {
		return fmt.Errorf("read patch metadata: %w", err)
	}
	var metadata PatchMetadata
	if err := json.Unmarshal(content, &metadata); err != nil {
		return fmt.Errorf("decode patch metadata: %w", err)
	}
	if metadata.CommitOID != v.Outcome.CommitOID ||
		metadata.StackRef != v.Outcome.StackRef ||
		metadata.PreparedEvidenceURI != v.Request.PreparedEvidenceURI ||
		metadata.PreparedTreeOID != v.Request.PreparedTreeOID ||
		metadata.EvidenceState != "sealed" {
		return errors.New("patch metadata does not link commit, ref, and prepared evidence")
	}
	return nil
}

type FinalizePatchRollback struct{}

func (FinalizePatchRollback) Restore(
	ctx context.Context,
	tx View,
	failure ClassifiedFailure,
) (*RecoveryReport, error) {
	if failure.RollbackClass != RollbackRefOnly {
		return manualRecovery("finalize rollback only supports ref_only recovery"), nil
	}
	var request FinalizePatchRequest
	if err := json.Unmarshal([]byte(tx.Snapshot().Operation), &request); err != nil {
		return manualRecovery("finalize operation snapshot is unreadable"), nil
	}
	stackRef := "refs/stack/patches/" + request.PatchID
	if oldOID, ok := tx.Snapshot().Refs[stackRef]; ok {
		if _, err := git(ctx, tx.Preflight().RepoRoot, "update-ref", stackRef, oldOID); err != nil {
			return failedRecovery("restore stack ref", err)
		}
	} else {
		if _, err := git(ctx, tx.Preflight().RepoRoot, "update-ref", "-d", stackRef); err != nil {
			return failedRecovery("delete new stack ref", err)
		}
	}
	for path, content := range tx.Snapshot().ArtifactState {
		if content == nil {
			if err := os.Remove(path); err != nil && !errors.Is(err, os.ErrNotExist) {
				return failedRecovery("remove new patch metadata", err)
			}
			continue
		}
		if err := writeAtomic(path, []byte(*content)); err != nil {
			return failedRecovery("restore patch metadata", err)
		}
	}
	return &RecoveryReport{State: StateRolledBack, Recovered: true}, nil
}

func NewFinalizePatchResponse(result *Result, request FinalizePatchRequest, outcome *FinalizeOutcome) FinalizePatchResponse {
	return FinalizePatchResponse{
		Transaction: StageTransactionResponse{
			TransactionID: result.TransactionID, Command: result.Command,
			State: result.State, OK: result.OK, Evidence: result.Evidence,
		},
		PatchID: request.PatchID, CommitOID: outcome.CommitOID,
		StackRef: outcome.StackRef, MetadataURI: outcome.MetadataURI,
	}
}

func writeAtomic(path string, content []byte) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return err
	}
	temp, err := os.CreateTemp(filepath.Dir(path), ".tmp-*")
	if err != nil {
		return err
	}
	tempPath := temp.Name()
	defer os.Remove(tempPath)
	if err := temp.Chmod(0o600); err != nil {
		_ = temp.Close()
		return err
	}
	if _, err := temp.Write(content); err != nil {
		_ = temp.Close()
		return err
	}
	if err := temp.Sync(); err != nil {
		_ = temp.Close()
		return err
	}
	if err := temp.Close(); err != nil {
		return err
	}
	return os.Rename(tempPath, path)
}

func failedRecovery(action string, err error) (*RecoveryReport, error) {
	return &RecoveryReport{
		State: StateRollbackFailed, ManualRequired: true,
		Notes: []string{fmt.Sprintf("%s: %v", action, err)},
	}, err
}
