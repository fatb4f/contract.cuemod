package pkg

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"cuelang.org/go/cue/format"
	"cuelang.org/go/cue/load"
	"github.com/mark3labs/mcp-go/mcp"
)

type cueAdapter struct {
	mu  sync.Mutex
	ctx *cue.Context
}

type cuePackageRequest struct {
	repoPath   string
	packageDir string
	path       string
	concrete   bool
}

func newCueAdapter() *cueAdapter {
	return &cueAdapter{ctx: cuecontext.New()}
}

func (s *GitServer) registerCueTools() {
	s.server.AddTool(mcp.NewTool("cue_eval",
		mcp.WithDescription("Evaluates CUE from an allowed repository without shelling out to the cue CLI"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to allowed Git repository"),
		),
		mcp.WithString("package_dir",
			mcp.Description("Package directory relative to repo_path (default: .)"),
		),
		mcp.WithString("path",
			mcp.Description("CUE path to evaluate, for example rootAgentContract.workspaceGraph"),
		),
		mcp.WithBoolean("concrete",
			mcp.Description("Require the evaluated value to be concrete"),
		),
	), s.cueEvalHandler)

	s.server.AddTool(mcp.NewTool("cue_validate",
		mcp.WithDescription("Validates CUE package constraints from an allowed repository"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to allowed Git repository"),
		),
		mcp.WithString("package_dir",
			mcp.Description("Package directory relative to repo_path (default: .)"),
		),
		mcp.WithString("path",
			mcp.Description("Optional CUE path to validate"),
		),
		mcp.WithBoolean("concrete",
			mcp.Description("Require the validated value to be concrete"),
		),
	), s.cueValidateHandler)

	s.server.AddTool(mcp.NewTool("ralph_runtime_preflight",
		mcp.WithDescription("Evaluates the RALPH runtime preflight fixture from the repository CUE contract"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to allowed repository containing AGENTS.cue"),
		),
		mcp.WithString("package_dir",
			mcp.Description("Package directory relative to repo_path (default: .)"),
		),
	), s.ralphRuntimePreflightHandler)

	s.server.AddTool(mcp.NewTool("ralph_git_mcp_allowlist",
		mcp.WithDescription("Evaluates the RALPH Git MCP repository allowlist projection from the CUE contract"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to allowed repository containing AGENTS.cue"),
		),
		mcp.WithString("package_dir",
			mcp.Description("Package directory relative to repo_path (default: .)"),
		),
	), s.ralphGitMCPAllowlistHandler)

	s.server.AddTool(mcp.NewTool("cue_symbol_resolve",
		mcp.WithDescription("Resolves a CUE symbol from an allowed repository as semantic evidence only"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to allowed Git repository"),
		),
		mcp.WithString("package_dir",
			mcp.Description("Package directory relative to repo_path (default: .)"),
		),
		mcp.WithString("symbol",
			mcp.Required(),
			mcp.Description("Canonical CUE symbol path to resolve"),
		),
	), s.cueSymbolResolveHandler)

	s.server.AddTool(mcp.NewTool("cue_symbol_references",
		mcp.WithDescription("Finds textual CUE references for a symbol inside an allowed package as semantic evidence only"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to allowed Git repository"),
		),
		mcp.WithString("package_dir",
			mcp.Description("Package directory relative to repo_path (default: .)"),
		),
		mcp.WithString("symbol",
			mcp.Required(),
			mcp.Description("Canonical CUE symbol path to find"),
		),
	), s.cueSymbolReferencesHandler)

	s.server.AddTool(mcp.NewTool("cue_diagnostics",
		mcp.WithDescription("Runs CUE package diagnostics from an allowed repository as semantic evidence only"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to allowed Git repository"),
		),
		mcp.WithString("package_dir",
			mcp.Description("Package directory relative to repo_path (default: .)"),
		),
	), s.cueDiagnosticsHandler)

	s.server.AddTool(mcp.NewTool("ralph_surface_resolve",
		mcp.WithDescription("Resolves a RALPH/CUE MCP surface to its canonical CUE binding as semantic evidence only"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to allowed repository containing AGENTS.cue"),
		),
		mcp.WithString("package_dir",
			mcp.Description("Package directory relative to repo_path (default: .)"),
		),
		mcp.WithString("surface",
			mcp.Required(),
			mcp.Description("RALPH/CUE MCP surface name"),
		),
	), s.ralphSurfaceResolveHandler)

	s.server.AddTool(mcp.NewTool("ralph_surface_preflight",
		mcp.WithDescription("Checks registered and setup-approved RALPH/CUE surfaces against canonical CUE bindings as semantic evidence only"),
		mcp.WithString("repo_path",
			mcp.Required(),
			mcp.Description("Path to allowed repository containing AGENTS.cue"),
		),
		mcp.WithString("package_dir",
			mcp.Description("Package directory relative to repo_path (default: .)"),
		),
	), s.ralphSurfacePreflightHandler)
}

func (s *GitServer) cueEvalHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	cueReq, err := s.parseCuePackageRequest(request)
	if err != nil {
		return mcp.NewToolResultError(err.Error()), nil
	}

	output, err := s.cue.evaluate(ctx, cueReq)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("CUE evaluation failed: %v", err)), nil
	}
	return mcp.NewToolResultText(output), nil
}

func (s *GitServer) cueValidateHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	cueReq, err := s.parseCuePackageRequest(request)
	if err != nil {
		return mcp.NewToolResultError(err.Error()), nil
	}

	if err := s.cue.validate(ctx, cueReq); err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("CUE validation failed: %v", err)), nil
	}
	return mcp.NewToolResultText(fmt.Sprintf("CUE validation succeeded for %s", cueReq.packagePath())), nil
}

func (s *GitServer) ralphRuntimePreflightHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	return s.ralphProjectionHandler(ctx, request, "runtimePreflightFixture")
}

func (s *GitServer) ralphGitMCPAllowlistHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	return s.ralphProjectionHandler(ctx, request, "gitMCPRepoAllowlistFixture")
}

func (s *GitServer) ralphProjectionHandler(ctx context.Context, request mcp.CallToolRequest, path string) (*mcp.CallToolResult, error) {
	cueReq, err := s.parseCuePackageRequest(request)
	if err != nil {
		return mcp.NewToolResultError(err.Error()), nil
	}
	cueReq.path = path

	output, err := s.cue.evaluate(ctx, cueReq)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("RALPH projection failed: %v", err)), nil
	}
	return mcp.NewToolResultText(output), nil
}

func (s *GitServer) parseCuePackageRequest(request mcp.CallToolRequest) (cuePackageRequest, error) {
	requestedPath, _ := request.Params.Arguments["repo_path"].(string)
	repoPath, err := s.getRepoPathForOperation(requestedPath)
	if err != nil {
		return cuePackageRequest{}, fmt.Errorf("repository path error: %w", err)
	}

	packageDir, _ := request.Params.Arguments["package_dir"].(string)
	if packageDir == "" {
		packageDir = "."
	}

	packagePath, err := cleanPathWithinRoot(repoPath, packageDir)
	if err != nil {
		return cuePackageRequest{}, err
	}
	info, err := os.Stat(packagePath)
	if err != nil {
		return cuePackageRequest{}, fmt.Errorf("package directory error: %w", err)
	}
	if !info.IsDir() {
		return cuePackageRequest{}, fmt.Errorf("package path is not a directory: %s", packagePath)
	}

	path, _ := request.Params.Arguments["path"].(string)
	concrete, _ := request.Params.Arguments["concrete"].(bool)
	return cuePackageRequest{
		repoPath:   repoPath,
		packageDir: packageDir,
		path:       strings.TrimSpace(path),
		concrete:   concrete,
	}, nil
}

func cleanPathWithinRoot(root, requested string) (string, error) {
	if filepath.IsAbs(requested) {
		return "", fmt.Errorf("package_dir must be relative to repo_path")
	}

	root = filepath.Clean(root)
	absPath := filepath.Clean(filepath.Join(root, requested))
	rel, err := filepath.Rel(root, absPath)
	if err != nil {
		return "", fmt.Errorf("package directory error: %w", err)
	}
	if rel == ".." || strings.HasPrefix(rel, ".."+string(filepath.Separator)) {
		return "", fmt.Errorf("package directory outside allowed repository: %s", requested)
	}
	return absPath, nil
}

func (r cuePackageRequest) packagePath() string {
	return filepath.Join(r.repoPath, r.packageDir)
}

func (a *cueAdapter) evaluate(ctx context.Context, req cuePackageRequest) (string, error) {
	value, err := a.loadValue(ctx, req)
	if err != nil {
		return "", err
	}

	if req.path != "" {
		path := cue.ParsePath(req.path)
		if err := path.Err(); err != nil {
			return "", err
		}
		value = value.LookupPath(path)
	}
	if err := validateCueValue(value, req.concrete); err != nil {
		return "", err
	}

	return formatCueValue(value)
}

func (a *cueAdapter) validate(ctx context.Context, req cuePackageRequest) error {
	value, err := a.loadValue(ctx, req)
	if err != nil {
		return err
	}

	if req.path != "" {
		path := cue.ParsePath(req.path)
		if err := path.Err(); err != nil {
			return err
		}
		value = value.LookupPath(path)
	}
	return validateCueValue(value, req.concrete)
}

func (a *cueAdapter) loadValue(ctx context.Context, req cuePackageRequest) (cue.Value, error) {
	select {
	case <-ctx.Done():
		return cue.Value{}, ctx.Err()
	default:
	}

	cfg := &load.Config{
		Dir:        req.packagePath(),
		ModuleRoot: req.repoPath,
	}

	instances := load.Instances([]string{"."}, cfg)
	if len(instances) == 0 {
		return cue.Value{}, fmt.Errorf("no CUE package found in %s", req.packagePath())
	}

	a.mu.Lock()
	defer a.mu.Unlock()

	value := a.ctx.BuildInstance(instances[0])
	if err := value.Err(); err != nil {
		return cue.Value{}, err
	}
	return value, nil
}

func validateCueValue(value cue.Value, concrete bool) error {
	options := []cue.Option{cue.Definitions(true), cue.Hidden(true), cue.Optional(true)}
	if concrete {
		options = append(options, cue.Concrete(true))
	}
	if err := value.Validate(options...); err != nil {
		return err
	}
	return nil
}

func formatCueValue(value cue.Value) (string, error) {
	syntax := value.Syntax(
		cue.Final(),
		cue.Definitions(true),
		cue.Hidden(true),
		cue.Optional(true),
	)
	bytes, err := format.Node(syntax)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(bytes)), nil
}
