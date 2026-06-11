package pkg

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"testing"

	"github.com/geropl/git-mcp-go/pkg/gitops/shell"
	"github.com/mark3labs/mcp-go/mcp"
	"github.com/stretchr/testify/require"
)

func initCueRepo(t *testing.T) string {
	t.Helper()

	repoDir := t.TempDir()
	cmd := exec.Command("git", "init")
	cmd.Dir = repoDir
	require.NoError(t, cmd.Run())

	require.NoError(t, os.MkdirAll(filepath.Join(repoDir, "cue.mod"), 0755))
	require.NoError(t, os.WriteFile(filepath.Join(repoDir, "cue.mod", "module.cue"), []byte(`module: "example.com/ralph"
language: version: "v0.14.0"
`), 0644))
	require.NoError(t, os.WriteFile(filepath.Join(repoDir, "AGENTS.cue"), []byte(`package ralph

rootAgentContract: {
	workspaceGraph: {
		root: "/tmp/workspace"
		nodes: [{
			id: "dotfiles"
			path: "/tmp/workspace/dotfiles"
		}]
	}
}

gitMCPRepoAllowlistFixture: {
	sourceGraph: "rootAgentContract.workspaceGraph"
	mcpServer: "git-mcp-server"
	repoPaths: ["/tmp/workspace/dotfiles"]
	policyBoundary: "CUE owns authorization policy; this adapter only evaluates projections."
}

runtimePreflightFixture: {
	selectedRepoPath: "/tmp/workspace/dotfiles"
	gitMCPAllowed: true
	cueSelectedTargetMatchesToolRuntimeCapability: true
	evidence: {
		authorizationSource: "root-policy"
		loadedFiles: [{
			path: "/tmp/workspace/dotfiles/AGENTS.cue"
			authorizedBy: "root-policy"
		}]
	}
}

ralphMCPBinding: {
	authorityPackage: "root.AGENTS"
	tools: {
		cue_eval: {
			canonical: true
			mode: "read-only"
			policyAuthority: "cue"
			adapterAuthority: "runtime-containment"
			adapterOwnsPolicy: false
			lspSymbol: "ralphMCPBinding.tools.cue_eval"
		}
		cue_validate: {
			canonical: true
			mode: "read-only"
			policyAuthority: "cue"
			adapterAuthority: "runtime-containment"
			adapterOwnsPolicy: false
			lspSymbol: "ralphMCPBinding.tools.cue_validate"
		}
		cue_symbol_resolve: {
			canonical: true
			mode: "read-only"
			policyAuthority: "cue"
			adapterAuthority: "runtime-containment"
			adapterOwnsPolicy: false
			lspSymbol: "ralphMCPBinding.tools.cue_symbol_resolve"
		}
		cue_symbol_references: {
			canonical: true
			mode: "read-only"
			policyAuthority: "cue"
			adapterAuthority: "runtime-containment"
			adapterOwnsPolicy: false
			lspSymbol: "ralphMCPBinding.tools.cue_symbol_references"
		}
		cue_diagnostics: {
			canonical: true
			mode: "read-only"
			policyAuthority: "cue"
			adapterAuthority: "runtime-containment"
			adapterOwnsPolicy: false
			lspSymbol: "ralphMCPBinding.tools.cue_diagnostics"
		}
		ralph_runtime_preflight: {
			canonical: true
			mode: "read-only"
			policyAuthority: "cue"
			adapterAuthority: "runtime-containment"
			adapterOwnsPolicy: false
			lspSymbol: "ralphMCPBinding.tools.ralph_runtime_preflight"
		}
		ralph_git_mcp_allowlist: {
			canonical: true
			mode: "read-only"
			policyAuthority: "cue"
			adapterAuthority: "runtime-containment"
			adapterOwnsPolicy: false
			lspSymbol: "ralphMCPBinding.tools.ralph_git_mcp_allowlist"
		}
		ralph_surface_resolve: {
			canonical: true
			mode: "read-only"
			policyAuthority: "cue"
			adapterAuthority: "runtime-containment"
			adapterOwnsPolicy: false
			lspSymbol: "ralphMCPBinding.tools.ralph_surface_resolve"
		}
		ralph_surface_preflight: {
			canonical: true
			mode: "read-only"
			policyAuthority: "cue"
			adapterAuthority: "runtime-containment"
			adapterOwnsPolicy: false
			lspSymbol: "ralphMCPBinding.tools.ralph_surface_preflight"
		}
	}
	deniedAuthoritySurfaces: ["cue-flow", "cueFlowLoopContract"]
	invariant: "semantic resolution is evidence only"
}
`), 0644))

	return repoDir
}

func callCueToolText(t *testing.T, result *mcp.CallToolResult, err error) string {
	t.Helper()
	require.NoError(t, err)
	require.NotNil(t, result)
	require.NotEmpty(t, result.Content)

	textContent, ok := mcp.AsTextContent(result.Content[0])
	require.True(t, ok)
	require.False(t, result.IsError, textContent.Text)
	return textContent.Text
}

func TestCueEvalHandler(t *testing.T) {
	repoDir := initCueRepo(t)
	gitOps := shell.NewShellGitOperations()
	server := NewGitServer([]string{repoDir}, gitOps, false)
	server.RegisterTools()

	request := mcp.CallToolRequest{}
	request.Params.Name = "cue_eval"
	request.Params.Arguments = map[string]interface{}{
		"repo_path": repoDir,
		"path":      "rootAgentContract.workspaceGraph.nodes",
	}

	result, err := server.cueEvalHandler(context.Background(), request)
	text := callCueToolText(t, result, err)
	require.Contains(t, text, `id:   "dotfiles"`)
	require.Contains(t, text, `path: "/tmp/workspace/dotfiles"`)
}

func TestCueValidateRejectsOutsidePackageDir(t *testing.T) {
	repoDir := initCueRepo(t)
	gitOps := shell.NewShellGitOperations()
	server := NewGitServer([]string{repoDir}, gitOps, false)
	server.RegisterTools()

	request := mcp.CallToolRequest{}
	request.Params.Name = "cue_validate"
	request.Params.Arguments = map[string]interface{}{
		"repo_path":   repoDir,
		"package_dir": "../outside",
	}

	result, err := server.cueValidateHandler(context.Background(), request)
	require.NoError(t, err)
	require.True(t, result.IsError)
}

func TestRalphProjectionHandlersSurfaceCueFixtures(t *testing.T) {
	repoDir := initCueRepo(t)
	gitOps := shell.NewShellGitOperations()
	server := NewGitServer([]string{repoDir}, gitOps, false)
	server.RegisterTools()

	request := mcp.CallToolRequest{}
	request.Params.Name = "ralph_runtime_preflight"
	request.Params.Arguments = map[string]interface{}{
		"repo_path": repoDir,
	}

	result, err := server.ralphRuntimePreflightHandler(context.Background(), request)
	text := callCueToolText(t, result, err)
	require.Contains(t, text, `authorizationSource: "root-policy"`)
	require.Contains(t, text, `cueSelectedTargetMatchesToolRuntimeCapability: true`)

	request.Params.Name = "ralph_git_mcp_allowlist"
	result, err = server.ralphGitMCPAllowlistHandler(context.Background(), request)
	text = callCueToolText(t, result, err)
	require.Contains(t, text, `policyBoundary: "CUE owns authorization policy; this adapter only evaluates projections."`)
	require.Contains(t, text, `repoPaths: ["/tmp/workspace/dotfiles"]`)
}

func TestRalphSurfacePreflightAcceptsCanonicalBindings(t *testing.T) {
	repoDir := initCueRepo(t)
	gitOps := shell.NewShellGitOperations()
	server := NewGitServer([]string{repoDir}, gitOps, false)
	server.RegisterTools()

	request := mcp.CallToolRequest{}
	request.Params.Name = "ralph_surface_preflight"
	request.Params.Arguments = map[string]interface{}{
		"repo_path": repoDir,
	}

	result, err := server.ralphSurfacePreflightHandler(context.Background(), request)
	text := callCueToolText(t, result, err)
	require.Contains(t, text, `"evidence_only": true`)
	require.Contains(t, text, `"cue_eval"`)
	require.Contains(t, text, `"ralph_surface_preflight"`)
}

func TestRalphSurfaceResolveRejectsLegacyAuthorityWording(t *testing.T) {
	repoDir := initCueRepo(t)
	gitOps := shell.NewShellGitOperations()
	server := NewGitServer([]string{repoDir}, gitOps, false)
	server.RegisterTools()

	request := mcp.CallToolRequest{}
	request.Params.Name = "ralph_surface_resolve"
	request.Params.Arguments = map[string]interface{}{
		"repo_path": repoDir,
		"surface":   "cue-flow",
	}

	result, err := server.ralphSurfaceResolveHandler(context.Background(), request)
	require.NoError(t, err)
	require.True(t, result.IsError)
}

func TestRalphSurfacePreflightRejectsRegisteredToolWithoutCueSymbol(t *testing.T) {
	repoDir := initCueRepo(t)
	adapter := newCueAdapter()
	req := cuePackageRequest{repoPath: repoDir, packageDir: "."}

	_, err := adapter.preflightRalphSurfaces(context.Background(), req, map[string]bool{
		"cue_eval":    true,
		"cue_phantom": true,
	}, map[string]bool{"cue_eval": true})
	require.ErrorContains(t, err, `registered RALPH/CUE tool "cue_phantom" has no canonical CUE symbol binding`)
}

func TestRalphSurfacePreflightRejectsCanonicalToolNotRegistered(t *testing.T) {
	repoDir := initCueRepo(t)
	adapter := newCueAdapter()
	req := cuePackageRequest{repoPath: repoDir, packageDir: "."}

	_, err := adapter.preflightRalphSurfaces(context.Background(), req, map[string]bool{
		"cue_eval": true,
	}, map[string]bool{"cue_eval": true})
	require.ErrorContains(t, err, "canonical CUE tool")
	require.ErrorContains(t, err, "is not registered in MCP")
}

func TestRalphSurfacePreflightRejectsSetupSnapshotWithoutCueSymbol(t *testing.T) {
	repoDir := initCueRepo(t)
	adapter := newCueAdapter()
	req := cuePackageRequest{repoPath: repoDir, packageDir: "."}

	registered := registeredRalphCueToolNames()
	_, err := adapter.preflightRalphSurfaces(context.Background(), req, registered, map[string]bool{
		"cue_eval":            true,
		"ralph_snapshot_only": true,
	})
	require.ErrorContains(t, err, `setup snapshot RALPH/CUE permission "ralph_snapshot_only" has no canonical CUE symbol binding`)
}

func TestCueSymbolHandlersResolveReferencesAndDiagnostics(t *testing.T) {
	repoDir := initCueRepo(t)
	gitOps := shell.NewShellGitOperations()
	server := NewGitServer([]string{repoDir}, gitOps, false)
	server.RegisterTools()

	request := mcp.CallToolRequest{}
	request.Params.Name = "cue_symbol_resolve"
	request.Params.Arguments = map[string]interface{}{
		"repo_path": repoDir,
		"symbol":    "ralphMCPBinding.tools.cue_eval",
	}
	result, err := server.cueSymbolResolveHandler(context.Background(), request)
	text := callCueToolText(t, result, err)
	require.Contains(t, text, `"resolved": true`)

	request.Params.Name = "cue_symbol_references"
	result, err = server.cueSymbolReferencesHandler(context.Background(), request)
	text = callCueToolText(t, result, err)
	require.Contains(t, text, `AGENTS.cue`)

	request.Params.Name = "cue_diagnostics"
	request.Params.Arguments = map[string]interface{}{
		"repo_path": repoDir,
	}
	result, err = server.cueDiagnosticsHandler(context.Background(), request)
	text = callCueToolText(t, result, err)
	require.Contains(t, text, `"clean": true`)
}
