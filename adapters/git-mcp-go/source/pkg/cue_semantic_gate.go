package pkg

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"cuelang.org/go/cue"
	"github.com/mark3labs/mcp-go/mcp"
)

type cueSymbolEvidence struct {
	Symbol           string `json:"symbol"`
	Resolved         bool   `json:"resolved"`
	AuthorityPath    string `json:"authority_path"`
	AuthorityPackage string `json:"authority_package,omitempty"`
	PackageDir       string `json:"package_dir"`
	EvidenceOnly     bool   `json:"evidence_only"`
}

type cueReferenceEvidence struct {
	Symbol       string   `json:"symbol"`
	References   []string `json:"references"`
	EvidenceOnly bool     `json:"evidence_only"`
}

type cueDiagnosticsEvidence struct {
	PackageDir   string `json:"package_dir"`
	Clean        bool   `json:"clean"`
	EvidenceOnly bool   `json:"evidence_only"`
}

type ralphSurfaceBinding struct {
	Name              string `json:"name"`
	Canonical         bool   `json:"canonical"`
	Mode              string `json:"mode"`
	PolicyAuthority   string `json:"policy_authority"`
	AdapterAuthority  string `json:"adapter_authority"`
	AdapterOwnsPolicy bool   `json:"adapter_owns_policy"`
	LSPSymbol         string `json:"lsp_symbol"`
}

type ralphSurfaceEvidence struct {
	Surface          string              `json:"surface"`
	AuthorityPackage string              `json:"authority_package"`
	Binding          ralphSurfaceBinding `json:"binding"`
	Symbol           cueSymbolEvidence   `json:"symbol"`
	EvidenceOnly     bool                `json:"evidence_only"`
}

type ralphSurfacePreflightEvidence struct {
	AuthorityPackage string   `json:"authority_package"`
	CanonicalTools   []string `json:"canonical_tools"`
	RegisteredTools  []string `json:"registered_tools"`
	SetupSnapshot    []string `json:"setup_snapshot"`
	EvidenceOnly     bool     `json:"evidence_only"`
}

func (s *GitServer) cueSymbolResolveHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	cueReq, err := s.parseCuePackageRequest(request)
	if err != nil {
		return mcp.NewToolResultError(err.Error()), nil
	}
	symbol, _ := request.Params.Arguments["symbol"].(string)

	evidence, err := s.cue.resolveSymbol(ctx, cueReq, symbol)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("CUE symbol resolution failed: %v", err)), nil
	}
	return jsonToolResult(evidence)
}

func (s *GitServer) cueSymbolReferencesHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	cueReq, err := s.parseCuePackageRequest(request)
	if err != nil {
		return mcp.NewToolResultError(err.Error()), nil
	}
	symbol, _ := request.Params.Arguments["symbol"].(string)

	evidence, err := s.cue.references(ctx, cueReq, symbol)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("CUE symbol reference lookup failed: %v", err)), nil
	}
	return jsonToolResult(evidence)
}

func (s *GitServer) cueDiagnosticsHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	cueReq, err := s.parseCuePackageRequest(request)
	if err != nil {
		return mcp.NewToolResultError(err.Error()), nil
	}
	if err := s.cue.validate(ctx, cueReq); err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("CUE diagnostics failed: %v", err)), nil
	}
	return jsonToolResult(cueDiagnosticsEvidence{
		PackageDir:   cueReq.packagePath(),
		Clean:        true,
		EvidenceOnly: true,
	})
}

func (s *GitServer) ralphSurfaceResolveHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	cueReq, err := s.parseCuePackageRequest(request)
	if err != nil {
		return mcp.NewToolResultError(err.Error()), nil
	}
	surface, _ := request.Params.Arguments["surface"].(string)

	evidence, err := s.cue.resolveRalphSurface(ctx, cueReq, surface)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("RALPH surface resolution failed: %v", err)), nil
	}
	return jsonToolResult(evidence)
}

func (s *GitServer) ralphSurfacePreflightHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	cueReq, err := s.parseCuePackageRequest(request)
	if err != nil {
		return mcp.NewToolResultError(err.Error()), nil
	}

	evidence, err := s.cue.preflightRalphSurfaces(ctx, cueReq, registeredRalphCueToolNames(), setupSnapshotRalphCueToolNames())
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("RALPH surface preflight failed: %v", err)), nil
	}
	return jsonToolResult(evidence)
}

func (a *cueAdapter) resolveSymbol(ctx context.Context, req cuePackageRequest, symbol string) (cueSymbolEvidence, error) {
	symbol = strings.TrimSpace(symbol)
	if symbol == "" {
		return cueSymbolEvidence{}, fmt.Errorf("symbol is required")
	}

	value, err := a.loadValue(ctx, req)
	if err != nil {
		return cueSymbolEvidence{}, err
	}
	path := cue.ParsePath(symbol)
	if err := path.Err(); err != nil {
		return cueSymbolEvidence{}, err
	}
	resolved := value.LookupPath(path)
	if err := validateCueValue(resolved, false); err != nil {
		return cueSymbolEvidence{}, err
	}

	return cueSymbolEvidence{
		Symbol:           symbol,
		Resolved:         true,
		AuthorityPath:    symbol,
		AuthorityPackage: lookupString(value, "ralphMCPBinding.authorityPackage"),
		PackageDir:       req.packagePath(),
		EvidenceOnly:     true,
	}, nil
}

func (a *cueAdapter) references(ctx context.Context, req cuePackageRequest, symbol string) (cueReferenceEvidence, error) {
	if _, err := a.resolveSymbol(ctx, req, symbol); err != nil {
		return cueReferenceEvidence{}, err
	}

	needle := lastPathSegment(symbol)
	refs := []string{}
	err := filepath.WalkDir(req.packagePath(), func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() {
			if entry.Name() == ".git" {
				return filepath.SkipDir
			}
			return nil
		}
		if filepath.Ext(path) != ".cue" {
			return nil
		}
		content, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		if strings.Contains(string(content), needle) || strings.Contains(string(content), symbol) {
			rel, err := filepath.Rel(req.packagePath(), path)
			if err != nil {
				return err
			}
			refs = append(refs, rel)
		}
		return nil
	})
	if err != nil {
		return cueReferenceEvidence{}, err
	}
	sort.Strings(refs)
	return cueReferenceEvidence{Symbol: symbol, References: refs, EvidenceOnly: true}, nil
}

func (a *cueAdapter) resolveRalphSurface(ctx context.Context, req cuePackageRequest, surface string) (ralphSurfaceEvidence, error) {
	surface = strings.TrimSpace(surface)
	if surface == "" {
		return ralphSurfaceEvidence{}, fmt.Errorf("surface is required")
	}

	value, err := a.loadValue(ctx, req)
	if err != nil {
		return ralphSurfaceEvidence{}, err
	}
	if isDeniedSurface(value, surface) {
		return ralphSurfaceEvidence{}, fmt.Errorf("surface %q is denied by the CUE semantic binding", surface)
	}

	binding, err := lookupSurfaceBinding(value, surface)
	if err != nil {
		return ralphSurfaceEvidence{}, err
	}
	if err := validateSurfaceBinding(binding); err != nil {
		return ralphSurfaceEvidence{}, err
	}

	symbol, err := a.resolveSymbol(ctx, req, binding.LSPSymbol)
	if err != nil {
		return ralphSurfaceEvidence{}, err
	}
	return ralphSurfaceEvidence{
		Surface:          surface,
		AuthorityPackage: lookupString(value, "ralphMCPBinding.authorityPackage"),
		Binding:          binding,
		Symbol:           symbol,
		EvidenceOnly:     true,
	}, nil
}

func (a *cueAdapter) preflightRalphSurfaces(ctx context.Context, req cuePackageRequest, registered, setupSnapshot map[string]bool) (ralphSurfacePreflightEvidence, error) {
	value, err := a.loadValue(ctx, req)
	if err != nil {
		return ralphSurfacePreflightEvidence{}, err
	}
	canonical, err := canonicalSurfaceNames(value)
	if err != nil {
		return ralphSurfacePreflightEvidence{}, err
	}

	for name := range registered {
		if !canonical[name] {
			return ralphSurfacePreflightEvidence{}, fmt.Errorf("registered RALPH/CUE tool %q has no canonical CUE symbol binding", name)
		}
		if _, err := a.resolveRalphSurface(ctx, req, name); err != nil {
			return ralphSurfacePreflightEvidence{}, err
		}
	}
	for name := range canonical {
		if !registered[name] {
			return ralphSurfacePreflightEvidence{}, fmt.Errorf("canonical CUE tool %q is not registered in MCP", name)
		}
	}
	for name := range setupSnapshot {
		if !canonical[name] {
			return ralphSurfacePreflightEvidence{}, fmt.Errorf("setup snapshot RALPH/CUE permission %q has no canonical CUE symbol binding", name)
		}
	}

	return ralphSurfacePreflightEvidence{
		AuthorityPackage: lookupString(value, "ralphMCPBinding.authorityPackage"),
		CanonicalTools:   sortedKeys(canonical),
		RegisteredTools:  sortedKeys(registered),
		SetupSnapshot:    sortedKeys(setupSnapshot),
		EvidenceOnly:     true,
	}, nil
}

func lookupSurfaceBinding(value cue.Value, name string) (ralphSurfaceBinding, error) {
	path := cue.ParsePath("ralphMCPBinding.tools." + name)
	if err := path.Err(); err != nil {
		return ralphSurfaceBinding{}, err
	}
	tool := value.LookupPath(path)
	if err := validateCueValue(tool, false); err != nil {
		return ralphSurfaceBinding{}, err
	}

	return ralphSurfaceBinding{
		Name:              name,
		Canonical:         lookupBool(tool, "canonical"),
		Mode:              lookupString(tool, "mode"),
		PolicyAuthority:   lookupString(tool, "policyAuthority"),
		AdapterAuthority:  lookupString(tool, "adapterAuthority"),
		AdapterOwnsPolicy: lookupBool(tool, "adapterOwnsPolicy"),
		LSPSymbol:         lookupString(tool, "lspSymbol"),
	}, nil
}

func validateSurfaceBinding(binding ralphSurfaceBinding) error {
	if !binding.Canonical {
		return fmt.Errorf("surface %q is not canonical", binding.Name)
	}
	if binding.Mode != "read-only" {
		return fmt.Errorf("surface %q mode %q is not read-only", binding.Name, binding.Mode)
	}
	if binding.PolicyAuthority != "cue" {
		return fmt.Errorf("surface %q policy authority %q is not cue", binding.Name, binding.PolicyAuthority)
	}
	if binding.AdapterAuthority != "runtime-containment" {
		return fmt.Errorf("surface %q adapter authority %q is not runtime-containment", binding.Name, binding.AdapterAuthority)
	}
	if binding.AdapterOwnsPolicy {
		return fmt.Errorf("surface %q claims adapter policy ownership", binding.Name)
	}
	if binding.LSPSymbol != "ralphMCPBinding.tools."+binding.Name {
		return fmt.Errorf("surface %q lsp symbol %q does not match canonical binding", binding.Name, binding.LSPSymbol)
	}
	return nil
}

func canonicalSurfaceNames(value cue.Value) (map[string]bool, error) {
	tools := value.LookupPath(cue.ParsePath("ralphMCPBinding.tools"))
	if err := validateCueValue(tools, false); err != nil {
		return nil, err
	}
	iter, err := tools.Fields()
	if err != nil {
		return nil, err
	}
	result := map[string]bool{}
	for iter.Next() {
		label := iter.Label()
		binding, err := lookupSurfaceBinding(value, label)
		if err != nil {
			return nil, err
		}
		if err := validateSurfaceBinding(binding); err != nil {
			return nil, err
		}
		result[label] = true
	}
	return result, nil
}

func registeredRalphCueToolNames() map[string]bool {
	return filterRalphCueToolNames(map[string]bool{
		"cue_eval":                true,
		"cue_validate":            true,
		"cue_symbol_resolve":      true,
		"cue_symbol_references":   true,
		"cue_diagnostics":         true,
		"ralph_runtime_preflight": true,
		"ralph_git_mcp_allowlist": true,
		"ralph_surface_resolve":   true,
		"ralph_surface_preflight": true,
	})
}

func setupSnapshotRalphCueToolNames() map[string]bool {
	return filterRalphCueToolNames(GetReadOnlyToolNames())
}

func filterRalphCueToolNames(tools map[string]bool) map[string]bool {
	result := map[string]bool{}
	for name, ok := range tools {
		if ok && (strings.HasPrefix(name, "cue_") || strings.HasPrefix(name, "ralph_")) {
			result[name] = true
		}
	}
	return result
}

func isDeniedSurface(value cue.Value, surface string) bool {
	denied := value.LookupPath(cue.ParsePath("ralphMCPBinding.deniedAuthoritySurfaces"))
	iter, err := denied.List()
	if err != nil {
		return false
	}
	for iter.Next() {
		if lookupScalarString(iter.Value()) == surface {
			return true
		}
	}
	return false
}

func lookupString(value cue.Value, path string) string {
	return lookupScalarString(value.LookupPath(cue.ParsePath(path)))
}

func lookupScalarString(value cue.Value) string {
	out, err := value.String()
	if err != nil {
		return ""
	}
	return out
}

func lookupBool(value cue.Value, path string) bool {
	out, err := value.LookupPath(cue.ParsePath(path)).Bool()
	if err != nil {
		return false
	}
	return out
}

func sortedKeys(values map[string]bool) []string {
	keys := make([]string, 0, len(values))
	for key, ok := range values {
		if ok {
			keys = append(keys, key)
		}
	}
	sort.Strings(keys)
	return keys
}

func lastPathSegment(path string) string {
	if idx := strings.LastIndex(path, "."); idx >= 0 {
		return path[idx+1:]
	}
	return path
}

func jsonToolResult(value interface{}) (*mcp.CallToolResult, error) {
	payload, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		return nil, err
	}
	return mcp.NewToolResultText(string(payload)), nil
}
