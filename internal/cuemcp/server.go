package cuemcp

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/base32"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"sync"

	"github.com/mark3labs/mcp-go/mcp"
	"github.com/mark3labs/mcp-go/server"
)

const (
	projectionSchema = "agent.context-projection.v1"
	searchPolicy     = "agent.search-policy.v1"
	rankingPolicy    = "agent.ranking-policy.v1"
	maxResultLimit   = 1000
)

type Runtime struct {
	root        string
	mu          sync.RWMutex
	projections map[string]projectionRecord
}

type projectionRecord struct {
	ID       string         `json:"projection_id"`
	Envelope map[string]any `json:"envelope"`
}

type resolveInput struct {
	Prompt     string   `json:"prompt"`
	CWD        string   `json:"cwd"`
	Candidates []string `json:"candidates"`
}

type searchInput struct {
	Schema       string   `json:"schema"`
	ProjectionID string   `json:"projection_id"`
	ArtifactIDs  []string `json:"artifact_ids"`
	Intent       string   `json:"intent"`
	Terms        []string `json:"terms"`
	ResultLimit  int      `json:"result_limit"`
}

type executionPlan struct {
	Backend string         `json:"backend"`
	Shell   bool           `json:"shell"`
	Terms   []string       `json:"terms"`
	Targets []searchTarget `json:"targets"`
}

type searchTarget struct {
	ArtifactID string `json:"artifact_id"`
	Path       string `json:"path"`
}

type searchResult struct {
	ID          string    `json:"id"`
	EvidenceID  string    `json:"evidence_id"`
	ProviderID  string    `json:"provider_id"`
	ArtifactID  string    `json:"artifact_id"`
	RankTuple   []float64 `json:"rank_tuple"`
	Kind        string    `json:"kind"`
	Path        string    `json:"path"`
	Line        int       `json:"line"`
	Column      int       `json:"column"`
	MatchedText string    `json:"matched_text"`
	Reason      string    `json:"reason"`
}

type rgEvent struct {
	Type string `json:"type"`
	Data struct {
		Path struct {
			Text string `json:"text"`
		} `json:"path"`
		Lines struct {
			Text string `json:"text"`
		} `json:"lines"`
		LineNumber int `json:"line_number"`
		Submatches []struct {
			Start int `json:"start"`
		} `json:"submatches"`
	} `json:"data"`
}

func New(root string) *Runtime {
	return &Runtime{root: root, projections: make(map[string]projectionRecord)}
}

func Serve(root string) error {
	runtime := New(root)
	s := server.NewMCPServer("cue", "0.1.0")

	s.AddTool(tool("resolve_agent_context", "Resolve authoritative CUE task context before repository inspection.", map[string]any{
		"prompt":     stringProperty("Current user prompt"),
		"cwd":        stringProperty("Current working directory"),
		"candidates": arrayProperty("Candidate capability IDs from the routing hint"),
	}, "prompt", "cwd"), runtime.handleResolve)
	s.AddTool(tool("lookup_projection", "Look up an in-memory immutable CUE authority envelope.", map[string]any{
		"projection_id": stringProperty("Projection authority-envelope identity"),
	}, "projection_id"), runtime.handleLookup)
	s.AddTool(tool("list_semantic_providers", "List the Stage 3 evidence and LSP-backed MCP provider contracts.", map[string]any{}), runtime.handleListProviders)
	s.AddTool(tool("search_implementation", "Search live implementation evidence inside CUE-projected bounds. Do not call rg directly when this tool applies.", map[string]any{
		"schema":        stringProperty("agent.search-implementation.request.v1"),
		"projection_id": stringProperty("Projection authority-envelope identity"),
		"artifact_ids":  arrayProperty("Graph artifact identities selected from the projection"),
		"intent":        stringProperty("Semantic search intent"),
		"terms":         arrayProperty("Literal search terms"),
		"result_limit":  numberProperty("Maximum returned evidence results"),
	}, "schema", "projection_id", "artifact_ids", "intent", "terms", "result_limit"), runtime.handleSearch)
	s.AddTool(tool("validate_projection", "Validate a projection envelope and its identity through CUE.", map[string]any{
		"projection_id": stringProperty("Projection authority-envelope identity"),
	}, "projection_id"), runtime.handleValidate)

	return server.ServeStdio(s)
}

func tool(name, description string, properties map[string]any, required ...string) mcp.Tool {
	return mcp.Tool{
		Name:        name,
		Description: description,
		InputSchema: mcp.ToolInputSchema{
			Type:       "object",
			Properties: properties,
			Required:   required,
		},
	}
}

func stringProperty(description string) map[string]any {
	return map[string]any{"type": "string", "description": description}
}

func numberProperty(description string) map[string]any {
	return map[string]any{"type": "integer", "description": description, "minimum": 1, "maximum": maxResultLimit}
}

func arrayProperty(description string) map[string]any {
	return map[string]any{
		"type":        "array",
		"description": description,
		"items":       map[string]any{"type": "string"},
	}
}

func (r *Runtime) handleResolve(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	input, err := decodeArguments[resolveInput](request.Params.Arguments)
	if err != nil {
		return toolError(err), nil
	}
	record, projection, err := r.Resolve(ctx, input)
	if err != nil {
		return toolError(err), nil
	}
	return jsonResult(map[string]any{
		"schema":        "agent.resolve-context.response.v1",
		"projection_id": record.ID,
		"envelope":      record.Envelope,
		"projection":    projection,
	}), nil
}

func (r *Runtime) handleLookup(_ context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	id, _ := request.Params.Arguments["projection_id"].(string)
	record, ok := r.lookup(id)
	if !ok {
		return jsonResult(searchError("projection_not_found", "Projection is not available in this MCP session.", id, map[string]any{})), nil
	}
	return jsonResult(map[string]any{
		"schema":        "agent.projection-lookup.response.v1",
		"projection_id": record.ID,
		"envelope":      record.Envelope,
	}), nil
}

func (r *Runtime) handleListProviders(ctx context.Context, _ mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	var providers map[string]any
	if err := r.cueExport(ctx, "stage3Providers", nil, &providers); err != nil {
		return toolError(err), nil
	}
	value := map[string]any{
		"schema":    "agent.semantic-providers.response.v1",
		"providers": providers,
	}
	if err := r.cueVet(ctx, "#SemanticProvidersResponse", value); err != nil {
		return toolError(err), nil
	}
	return jsonResult(value), nil
}

func (r *Runtime) handleSearch(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	input, err := decodeArguments[searchInput](request.Params.Arguments)
	if err != nil {
		return toolError(err), nil
	}
	result, searchErr := r.Search(ctx, input)
	if searchErr != nil {
		return jsonResult(searchErr), nil
	}
	return jsonResult(result), nil
}

func (r *Runtime) handleValidate(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	id, _ := request.Params.Arguments["projection_id"].(string)
	record, ok := r.lookup(id)
	if !ok {
		return jsonResult(searchError("projection_not_found", "Projection is not available in this MCP session.", id, map[string]any{})), nil
	}
	actual, err := projectionID(record.Envelope)
	if err != nil {
		return toolError(err), nil
	}
	if actual != id {
		return jsonResult(searchError("projection_hash_mismatch", "Projection identity does not match its authority envelope.", id, map[string]any{
			"expected_projection_id": id,
			"actual_projection_id":   actual,
		})), nil
	}
	value := map[string]any{
		"schema":        "agent.projection-lookup.response.v1",
		"projection_id": id,
		"envelope":      record.Envelope,
	}
	if err := r.cueVet(ctx, "#ProjectionLookupResponse", value); err != nil {
		return toolError(err), nil
	}
	return jsonResult(map[string]any{"schema": "agent.validate-projection.response.v1", "projection_id": id, "valid": true}), nil
}

func (r *Runtime) Resolve(ctx context.Context, input resolveInput) (projectionRecord, map[string]any, error) {
	if strings.TrimSpace(input.Prompt) == "" {
		return projectionRecord{}, nil, errors.New("prompt is required")
	}
	if input.CWD == "" {
		input.CWD = r.root
	}
	value := map[string]any{"resolverInput": map[string]any{
		"prompt":                input.Prompt,
		"cwd":                   input.CWD,
		"candidateCapabilities": input.Candidates,
	}}
	var projection map[string]any
	if err := r.cueExport(ctx, "agentContextProjection", value, &projection); err != nil {
		return projectionRecord{}, nil, err
	}
	envelope := map[string]any{
		"schema":                    "agent.projection-envelope.v1",
		"projection_schema_version": projectionSchema,
		"projection":                projection,
		"search_policy_version":     searchPolicy,
		"ranking_policy_version":    rankingPolicy,
	}
	id, err := projectionID(envelope)
	if err != nil {
		return projectionRecord{}, nil, err
	}
	record := projectionRecord{ID: id, Envelope: envelope}
	if err := r.cueVet(ctx, "#ProjectionLookupResponse", map[string]any{
		"schema":        "agent.projection-lookup.response.v1",
		"projection_id": id,
		"envelope":      envelope,
	}); err != nil {
		return projectionRecord{}, nil, err
	}
	r.mu.Lock()
	r.projections[id] = record
	r.mu.Unlock()
	return record, projection, nil
}

func (r *Runtime) Search(ctx context.Context, input searchInput) (map[string]any, map[string]any) {
	if input.Schema != "agent.search-implementation.request.v1" {
		return nil, searchError("invalid_search_contract", "Unexpected request schema.", input.ProjectionID, map[string]any{"field": "schema"})
	}
	if input.ResultLimit < 1 || input.ResultLimit > maxResultLimit {
		return nil, searchError("result_limit_exceeded", "Result limit exceeds search policy.", input.ProjectionID, map[string]any{
			"requested": input.ResultLimit,
			"maximum":   maxResultLimit,
		})
	}
	if strings.TrimSpace(input.Intent) == "" || len(input.ArtifactIDs) == 0 || len(input.Terms) == 0 {
		return nil, searchError("invalid_search_contract", "Intent, artifact_ids, and terms are required.", input.ProjectionID, map[string]any{})
	}
	for _, term := range input.Terms {
		if strings.TrimSpace(term) == "" {
			return nil, searchError("term_not_allowed", "Search terms must be non-empty literals.", input.ProjectionID, map[string]any{"term": term})
		}
	}
	record, ok := r.lookup(input.ProjectionID)
	if !ok {
		return nil, searchError("projection_not_found", "Projection is not available in this MCP session.", input.ProjectionID, map[string]any{})
	}
	actual, err := projectionID(record.Envelope)
	if err != nil || actual != input.ProjectionID {
		return nil, searchError("projection_hash_mismatch", "Projection identity does not match its authority envelope.", input.ProjectionID, map[string]any{
			"expected_projection_id": input.ProjectionID,
			"actual_projection_id":   actual,
		})
	}

	planInput := map[string]any{"searchPlanInput": map[string]any{
		"envelope": record.Envelope,
		"request":  input,
	}}
	var plan executionPlan
	if err := r.cueExport(ctx, "searchExecutionPlan", planInput, &plan); err != nil {
		return nil, searchError("invalid_search_contract", err.Error(), input.ProjectionID, map[string]any{})
	}
	if err := validatePlan(plan); err != nil {
		return nil, searchError("invalid_search_contract", err.Error(), input.ProjectionID, map[string]any{})
	}

	projection := record.Envelope["projection"].(map[string]any)
	project := projection["project"].(map[string]any)
	projectRoot := project["root"].(string)
	if err := validateSearchTargets(projectRoot, plan.Targets); err != nil {
		return nil, searchError("path_out_of_scope", err.Error(), input.ProjectionID, map[string]any{
			"requested_path": strings.Join(targetPaths(plan.Targets), ","),
			"allowed_roots":  targetPaths(plan.Targets),
		})
	}
	results, invocations, backendVersion, backendErr := executeRG(ctx, projectRoot, input.ProjectionID, plan)
	if backendErr != nil {
		code := "backend_failed"
		details := map[string]any{"backend": "rg"}
		if errors.Is(backendErr, exec.ErrNotFound) {
			code = "backend_unavailable"
		} else {
			details["exit_code"] = -1
			var exitErr *exec.ExitError
			if errors.As(backendErr, &exitErr) {
				details["exit_code"] = exitErr.ExitCode()
				details["stderr"] = strings.TrimSpace(string(exitErr.Stderr))
			}
		}
		return nil, searchError(code, backendErr.Error(), input.ProjectionID, details)
	}

	sortResults(results)
	truncated := len(results) > input.ResultLimit
	if truncated {
		results = results[:input.ResultLimit]
	}
	var cursor any
	if truncated {
		cursor = results[len(results)-1].ID
	}
	response := map[string]any{
		"schema":        "agent.search-implementation.response.v1",
		"projection_id": input.ProjectionID,
		"execution": map[string]any{
			"backend":         "rg",
			"provider_id":     "df:provider/cue-rg-mcp",
			"backend_version": backendVersion,
			"shell":           false,
			"invocations":     invocations,
		},
		"pagination": map[string]any{
			"result_limit": input.ResultLimit,
			"returned":     len(results),
			"truncated":    truncated,
			"next_cursor":  cursor,
		},
		"ordering": map[string]any{
			"policy": rankingPolicy,
			"sort":   []string{"rank_tuple desc", "path asc", "line asc", "id asc"},
		},
		"results": results,
		"coverage": map[string]any{
			"selected_artifacts":     input.ArtifactIDs,
			"searched_artifacts":     targetArtifactIDs(plan.Targets),
			"truncated":              truncated,
			"negative_claim_allowed": false,
			"reason":                 "Text search returns evidence observations only; empty or complete-looking results do not prove semantic absence.",
		},
	}
	if err := r.cueVet(ctx, "#SearchImplementationResponse", response); err != nil {
		return nil, searchError("invalid_search_contract", err.Error(), input.ProjectionID, map[string]any{})
	}
	return response, nil
}

func (r *Runtime) lookup(id string) (projectionRecord, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	record, ok := r.projections[id]
	return record, ok
}

func (r *Runtime) cueExport(ctx context.Context, expression string, input any, output any) error {
	args := []string{"export", ".", "dotfiles.schema-map.json"}
	if input != nil {
		inputPath, cleanup, err := writeTempJSON(input)
		if err != nil {
			return err
		}
		defer cleanup()
		args = append(args, inputPath)
	}
	args = append(args, "-e", expression, "--out", "json")
	cmd := exec.CommandContext(ctx, "cue", args...)
	cmd.Dir = r.root
	data, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("cue export %s: %w: %s", expression, err, strings.TrimSpace(string(data)))
	}
	if err := json.Unmarshal(data, output); err != nil {
		return fmt.Errorf("decode CUE projection: %w", err)
	}
	return nil
}

func (r *Runtime) cueVet(ctx context.Context, definition string, value any) error {
	inputPath, cleanup, err := writeTempJSON(value)
	if err != nil {
		return err
	}
	defer cleanup()
	cmd := exec.CommandContext(ctx, "cue", "vet", "-c", "-d", definition, ".", inputPath)
	cmd.Dir = r.root
	data, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("cue vet %s: %w: %s", definition, err, strings.TrimSpace(string(data)))
	}
	return nil
}

func writeTempJSON(value any) (string, func(), error) {
	file, err := os.CreateTemp("", "cue-mcp-*.json")
	if err != nil {
		return "", nil, err
	}
	cleanup := func() { _ = os.Remove(file.Name()) }
	encoder := json.NewEncoder(file)
	if err := encoder.Encode(value); err != nil {
		_ = file.Close()
		cleanup()
		return "", nil, err
	}
	if err := file.Close(); err != nil {
		cleanup()
		return "", nil, err
	}
	return file.Name(), cleanup, nil
}

func projectionID(envelope map[string]any) (string, error) {
	data, err := json.Marshal(envelope)
	if err != nil {
		return "", err
	}
	sum := sha256.Sum256(data)
	return "sha256:" + hex.EncodeToString(sum[:]), nil
}

func validatePlan(plan executionPlan) error {
	if plan.Backend != "rg" || plan.Shell || len(plan.Terms) == 0 || len(plan.Targets) == 0 {
		return errors.New("CUE search plan violated the artifact-bound rg contract")
	}
	for _, target := range plan.Targets {
		if target.ArtifactID == "" || filepath.IsAbs(target.Path) || strings.Contains(filepath.ToSlash(target.Path), "../") || target.Path == ".." {
			return fmt.Errorf("CUE search plan produced an unsafe artifact target: %s", target.Path)
		}
	}
	return nil
}

func validateSearchTargets(root string, targets []searchTarget) error {
	realRoot, err := filepath.EvalSymlinks(root)
	if err != nil {
		return err
	}
	for _, target := range targets {
		realPath, err := filepath.EvalSymlinks(filepath.Join(root, target.Path))
		if err != nil {
			return err
		}
		relative, err := filepath.Rel(realRoot, realPath)
		if err != nil || relative == ".." || strings.HasPrefix(relative, ".."+string(filepath.Separator)) {
			return fmt.Errorf("projected artifact path resolves outside repository root: %s", target.Path)
		}
	}
	return nil
}

func executeRG(ctx context.Context, root, projectionID string, plan executionPlan) ([]searchResult, []map[string]any, string, error) {
	versionCmd := exec.CommandContext(ctx, "rg", "--version")
	versionData, err := versionCmd.Output()
	if err != nil {
		return nil, nil, "", err
	}
	version := strings.TrimSpace(strings.SplitN(string(versionData), "\n", 2)[0])
	results := make([]searchResult, 0)
	invocations := make([]map[string]any, 0, len(plan.Targets))
	for _, target := range plan.Targets {
		argv := rgArgv(plan.Terms, target.Path)
		invocations = append(invocations, map[string]any{
			"artifact_id": target.ArtifactID,
			"argv":        argv,
			"path":        target.Path,
		})
		cmd := exec.CommandContext(ctx, argv[0], argv[1:]...)
		cmd.Dir = root
		output, err := cmd.Output()
		if err != nil {
			var exitErr *exec.ExitError
			if errors.As(err, &exitErr) && exitErr.ExitCode() == 1 {
				continue
			}
			return nil, invocations, version, err
		}
		for _, line := range bytes.Split(output, []byte{'\n'}) {
			if len(line) == 0 {
				continue
			}
			var event rgEvent
			if json.Unmarshal(line, &event) != nil || event.Type != "match" {
				continue
			}
			column := 1
			if len(event.Data.Submatches) > 0 {
				column = event.Data.Submatches[0].Start + 1
			}
			text := strings.TrimSuffix(event.Data.Lines.Text, "\n")
			id := evidenceID(projectionID, event.Data.Path.Text, event.Data.LineNumber, column, text)
			results = append(results, searchResult{
				ID:          id,
				EvidenceID:  id,
				ProviderID:  "df:provider/cue-rg-mcp",
				ArtifactID:  target.ArtifactID,
				RankTuple:   []float64{0.8, 0, 0},
				Kind:        "source",
				Path:        event.Data.Path.Text,
				Line:        event.Data.LineNumber,
				Column:      column,
				MatchedText: text,
				Reason:      "literal evidence from an explicitly selected graph artifact",
			})
		}
	}
	return results, invocations, version, nil
}

func rgArgv(terms []string, path string) []string {
	argv := []string{"rg", "--json", "--line-number", "--column", "--smart-case", "--fixed-strings"}
	for _, term := range terms {
		argv = append(argv, "-e", term)
	}
	return append(argv, "--", path)
}

func targetPaths(targets []searchTarget) []string {
	paths := make([]string, 0, len(targets))
	for _, target := range targets {
		paths = append(paths, target.Path)
	}
	return paths
}

func targetArtifactIDs(targets []searchTarget) []string {
	ids := make([]string, 0, len(targets))
	for _, target := range targets {
		ids = append(ids, target.ArtifactID)
	}
	return ids
}

func evidenceID(projectionID, path string, line, column int, matchedText string) string {
	value := strings.Join([]string{projectionID, path, strconv.Itoa(line), strconv.Itoa(column), matchedText}, "\x00")
	sum := sha256.Sum256([]byte(value))
	encoded := base32.StdEncoding.WithPadding(base32.NoPadding).EncodeToString(sum[:])
	return "ev_" + strings.ToLower(encoded[:16])
}

func sortResults(results []searchResult) {
	sort.Slice(results, func(i, j int) bool {
		for index := range results[i].RankTuple {
			if results[i].RankTuple[index] != results[j].RankTuple[index] {
				return results[i].RankTuple[index] > results[j].RankTuple[index]
			}
		}
		if results[i].Path != results[j].Path {
			return results[i].Path < results[j].Path
		}
		if results[i].Line != results[j].Line {
			return results[i].Line < results[j].Line
		}
		return results[i].ID < results[j].ID
	})
}

func searchError(code, message, projectionID string, details map[string]any) map[string]any {
	return map[string]any{
		"schema":        "agent.search-implementation.error.v1",
		"code":          code,
		"message":       message,
		"projection_id": projectionID,
		"details":       details,
	}
}

func decodeArguments[T any](arguments map[string]any) (T, error) {
	var output T
	data, err := json.Marshal(arguments)
	if err != nil {
		return output, err
	}
	if err := json.Unmarshal(data, &output); err != nil {
		return output, err
	}
	return output, nil
}

func jsonResult(value any) *mcp.CallToolResult {
	data, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		return toolError(err)
	}
	return mcp.NewToolResultText(string(data))
}

func toolError(err error) *mcp.CallToolResult {
	return mcp.NewToolResultError(err.Error())
}
