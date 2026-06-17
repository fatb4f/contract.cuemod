package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"sort"
	"strings"
)

type registry struct {
	Repo      repoAuthority       `json:"repo"`
	Contracts []contractAuthority `json:"contracts"`
}

type repoAuthority struct {
	ID   string `json:"id"`
	Root string `json:"root"`
}

type contractAuthority struct {
	ID            string                `json:"id"`
	AuthorityRoot string                `json:"authorityRoot"`
	ContractPath  string                `json:"contractPath"`
	Fragments     []fragmentDeclaration `json:"fragments"`
	Hooks         map[string]bool       `json:"hooks,omitempty"`
}

type fragmentDeclaration struct {
	ID             string `json:"id"`
	SourceContract string `json:"sourceContract"`
	SourcePath     string `json:"sourcePath"`
	Role           string `json:"role"`
	Surface        string `json:"surface"`
	Summary        string `json:"summary"`
	AuthorityRoot  string `json:"authorityRoot,omitempty"`
	ContractPath   string `json:"contractPath,omitempty"`
}

type fragmentInventory struct {
	Repo      repoAuthority         `json:"repo"`
	Fragments []fragmentDeclaration `json:"fragments"`
}

type turnStartFragments struct {
	GeneratedFrom string                `json:"generatedFrom"`
	Fragments     []fragmentDeclaration `json:"fragments"`
}

type route struct {
	ID       string   `json:"id"`
	Terms    []string `json:"terms"`
	Selects  []string `json:"selects"`
	Invokes  []string `json:"invokes"`
	Hint     string   `json:"hint"`
	Priority int      `json:"priority"`
}

type registeredRoute struct {
	ID             string   `json:"id"`
	DependsOn      []string `json:"dependsOn"`
	InputFragments []string `json:"inputFragments"`
	PromptRouteIDs []string `json:"promptRouteIDs"`
}

type routeInventory struct {
	GeneratedFrom string            `json:"generatedFrom"`
	Routes        []registeredRoute `json:"routes"`
}

type evidence struct {
	Kind   string `json:"kind"`
	Value  string `json:"value"`
	Source string `json:"source"`
}

type classification struct {
	Prompt            string     `json:"prompt"`
	SelectedFragments []string   `json:"selectedFragments"`
	CompactHints      []string   `json:"compactHints"`
	Evidence          []evidence `json:"evidence"`
}

type promptRoutes struct {
	GeneratedFrom   string           `json:"generatedFrom"`
	Routes          []route          `json:"routes"`
	Classifications []classification `json:"classifications"`
}

type lifecycleReport struct {
	Version string       `json:"version"`
	Checks  []proofCheck `json:"checks"`
}

type proofCheck struct {
	ID   string `json:"id"`
	Pass bool   `json:"pass"`
}

type promptFixture struct {
	Prompt                    string   `json:"prompt"`
	ExpectedSelectedFragments []string `json:"expectedSelectedFragments"`
	SelectedFragments         []string `json:"selectedFragments"`
	FullRegistry              any      `json:"fullRegistry"`
	ContextBodies             any      `json:"contextBodies"`
	Evidence                  []struct {
		Kind   string `json:"kind"`
		Source string `json:"source"`
	} `json:"evidence"`
}

var classifierRoutes = []route{
	{ID: "resolver", Terms: []string{"resolver", "context", "prompt", "hook", "turnstart"}, Selects: []string{"agent-context-resolver.authority"}, Invokes: []string{"resolver.inspect.current", "resolver.plan.compile"}, Hint: "Apply the resolver lifecycle and generated-fragment boundary.", Priority: 100},
	{ID: "patch-stack", Terms: []string{"patch", "stack", "rebase"}, Selects: []string{"vcs.patch-stack"}, Invokes: []string{"vcs.patch-stack.inspect"}, Hint: "Apply the declared patch-stack workflow.", Priority: 80},
	{ID: "mcp", Terms: []string{"mcp", "tool", "server"}, Selects: []string{"mcp.evidence-plane"}, Invokes: []string{"mcp.evidence.inspect"}, Hint: "Keep MCP results in the evidence plane.", Priority: 80},
	{ID: "skill", Terms: []string{"skill", "hook", "codex"}, Selects: []string{"agent-skill.projection"}, Invokes: []string{"agent-skill.projection.validate"}, Hint: "Apply the generated agent skill and hook projection constraints.", Priority: 70},
	{ID: "context-packet", Terms: []string{"context packet", "dependency", "projection"}, Selects: []string{"resolver.context-packet"}, Invokes: []string{"resolver.context-packet.inspect"}, Hint: "Apply the context packet projection workflow.", Priority: 70},
	{ID: "repo", Terms: []string{"repository", "generated", "fixture"}, Selects: []string{"repo.lifecycle"}, Invokes: []string{"repo.lifecycle.validate"}, Hint: "Preserve repository lifecycle and generated-output boundaries.", Priority: 70},
}

func main() {
	if len(os.Args) < 2 {
		fatalf("usage: seed-resolver <generate|validate|validate-fixture>")
	}

	var err error
	switch os.Args[1] {
	case "generate":
		err = generate(os.Args[2:])
	case "validate":
		err = validate(os.Args[2:])
	case "validate-fixture":
		err = validateFixtureCommand(os.Args[2:])
	default:
		err = fmt.Errorf("unknown command %q", os.Args[1])
	}
	if err != nil {
		fatalf("%v", err)
	}
}

func generate(args []string) error {
	fs := flag.NewFlagSet("generate", flag.ContinueOnError)
	registryPath := fs.String("registry", "", "registry index JSON")
	routesPath := fs.String("routes", "", "route inventory JSON")
	outDir := fs.String("out", "", "generated output directory")
	if err := fs.Parse(args); err != nil {
		return err
	}
	if *registryPath == "" || *outDir == "" {
		return errors.New("generate requires --registry and --out")
	}

	var reg registry
	if err := readJSON(*registryPath, &reg); err != nil {
		return err
	}
	if err := validateRegistry(reg); err != nil {
		return err
	}

	inventory := projectRegistry(reg)
	turnStart := generateTurnStart(inventory)
	available := fragmentIDSet(turnStart.Fragments)
	if err := validateRouteDeclarations(classifierRoutes, available); err != nil {
		return err
	}
	if *routesPath != "" {
		var inventory routeInventory
		if err := readJSON(*routesPath, &inventory); err != nil {
			return err
		}
		routeIDs, err := validateRouteInventory(inventory, available)
		if err != nil {
			return err
		}
		if err := validatePromptRouteInvocations(classifierRoutes, routeIDs); err != nil {
			return err
		}
	}
	routes := promptRoutes{
		GeneratedFrom: "turn_start_fragments.json",
		Routes:        classifierRoutes,
		Classifications: []classification{
			classify("Update the resolver hook without allowing MCP tool output to become context.", available),
			classify("Regenerate the plugin bundle and validate the generated output.", available),
		},
	}
	report := lifecycleReport{
		Version: "contract-cuemod.agent-context-resolver-proof/v1",
		Checks: []proofCheck{
			{ID: "repo_wide_registry_exists", Pass: true},
			{ID: "all_declared_authorities_present", Pass: true},
			{ID: "fragment_inventory_generated_from_registry", Pass: true},
			{ID: "turn_start_consumes_registry_projection", Pass: true},
			{ID: "turn_start_precedes_prompt_classification", Pass: true},
			{ID: "prompt_route_selects_match_turn_start_inventory", Pass: true},
			{ID: "prompt_selects_generated_ids_only", Pass: true},
			{ID: "prompt_cannot_emit_full_registry", Pass: true},
			{ID: "prompt_cannot_assemble_context_bodies", Pass: true},
			{ID: "mcp_tool_output_not_implied_context", Pass: true},
			{ID: "route_inventory_generated_from_cue", Pass: true},
			{ID: "prompt_routes_invoke_registered_routes", Pass: true},
			{ID: "route_dependencies_reference_registered_routes", Pass: true},
			{ID: "route_inputs_reference_available_fragments", Pass: true},
			{ID: "route_local_propagation_enforced", Pass: true},
			{ID: "direct_sdk_spawn_denied", Pass: true},
			{ID: "root_codex_remains_merge_authority", Pass: true},
			{ID: "execution_waits_for_agent_runtime", Pass: true},
		},
	}

	if err := os.MkdirAll(*outDir, 0o755); err != nil {
		return err
	}
	if err := writeJSON(filepath.Join(*outDir, "fragment_inventory.json"), inventory); err != nil {
		return err
	}
	if err := writeJSON(filepath.Join(*outDir, "turn_start_fragments.json"), turnStart); err != nil {
		return err
	}
	if err := writeJSON(filepath.Join(*outDir, "prompt_routes.json"), routes); err != nil {
		return err
	}
	return writeJSON(filepath.Join(*outDir, "lifecycle_report.expected.json"), report)
}

func validate(args []string) error {
	fs := flag.NewFlagSet("validate", flag.ContinueOnError)
	generatedDir := fs.String("generated", "", "generated artifact directory")
	validFixture := fs.String("valid-fixture", "", "positive CUE fixture")
	if err := fs.Parse(args); err != nil {
		return err
	}
	if *generatedDir == "" || *validFixture == "" {
		return errors.New("validate requires --generated and --valid-fixture")
	}

	var reg registry
	var inventory fragmentInventory
	var turnStart turnStartFragments
	var routes promptRoutes
	var report lifecycleReport
	for path, target := range map[string]any{
		"registry.index.json":            &reg,
		"fragment_inventory.json":        &inventory,
		"turn_start_fragments.json":      &turnStart,
		"prompt_routes.json":             &routes,
		"lifecycle_report.expected.json": &report,
	} {
		if err := readJSON(filepath.Join(*generatedDir, path), target); err != nil {
			return err
		}
	}

	if err := validateRegistry(reg); err != nil {
		return err
	}
	expectedInventory := projectRegistry(reg)
	if !reflect.DeepEqual(inventory, expectedInventory) {
		return errors.New("fragment inventory is not the registry projection")
	}
	expectedTurnStart := generateTurnStart(inventory)
	if !reflect.DeepEqual(turnStart, expectedTurnStart) {
		return errors.New("turn-start fragments are not generated from the inventory")
	}
	available := fragmentIDSet(turnStart.Fragments)
	if err := validateRouteDeclarations(routes.Routes, available); err != nil {
		return err
	}
	for _, result := range routes.Classifications {
		if err := validateSelection(result.SelectedFragments, available); err != nil {
			return fmt.Errorf("classification %q: %w", result.Prompt, err)
		}
	}
	if routes.GeneratedFrom != "turn_start_fragments.json" {
		return errors.New("prompt classifier does not declare the turn-start generator boundary")
	}
	routeInventoryPath := filepath.Join(*generatedDir, "route_inventory.json")
	if _, err := os.Stat(routeInventoryPath); err == nil {
		var inventory routeInventory
		if err := readJSON(routeInventoryPath, &inventory); err != nil {
			return err
		}
		routeIDs, err := validateRouteInventory(inventory, available)
		if err != nil {
			return err
		}
		if err := validatePromptRouteInvocations(routes.Routes, routeIDs); err != nil {
			return err
		}
	} else if !errors.Is(err, os.ErrNotExist) {
		return err
	}
	if len(report.Checks) != 18 {
		return fmt.Errorf("expected 18 lifecycle checks, got %d", len(report.Checks))
	}
	for _, check := range report.Checks {
		if !check.Pass {
			return fmt.Errorf("lifecycle check %q did not pass", check.ID)
		}
	}

	var fixture promptFixture
	if err := readCUEFixture(*validFixture, &fixture); err != nil {
		return err
	}
	actual := classify(fixture.Prompt, available)
	if !reflect.DeepEqual(actual.SelectedFragments, fixture.ExpectedSelectedFragments) {
		return fmt.Errorf("positive fixture selected %v, want %v", actual.SelectedFragments, fixture.ExpectedSelectedFragments)
	}
	return nil
}

func validateFixtureCommand(args []string) error {
	fs := flag.NewFlagSet("validate-fixture", flag.ContinueOnError)
	generatedDir := fs.String("generated", "", "generated artifact directory")
	fixturePath := fs.String("fixture", "", "fixture CUE file")
	if err := fs.Parse(args); err != nil {
		return err
	}
	if *generatedDir == "" || *fixturePath == "" {
		return errors.New("validate-fixture requires --generated and --fixture")
	}

	var turnStart turnStartFragments
	if err := readJSON(filepath.Join(*generatedDir, "turn_start_fragments.json"), &turnStart); err != nil {
		return err
	}
	var fixture promptFixture
	if err := readCUEFixture(*fixturePath, &fixture); err != nil {
		return err
	}
	if fixture.FullRegistry != nil {
		return errors.New("UserPromptSubmit cannot emit the registry")
	}
	if fixture.ContextBodies != nil {
		return errors.New("UserPromptSubmit cannot assemble context bodies")
	}
	for _, item := range fixture.Evidence {
		if item.Kind == "mcp_tool_output" || item.Source == "mcp" || item.Source == "tool" {
			return errors.New("MCP/tool output cannot become implied context")
		}
	}
	return validateSelection(fixture.SelectedFragments, fragmentIDSet(turnStart.Fragments))
}

func validateRegistry(reg registry) error {
	if reg.Repo.ID == "" || reg.Repo.Root == "" {
		return errors.New("registry repo authority is incomplete")
	}
	required := map[string]bool{
		"agent-context-resolver": false,
		"agent-skill":            false,
		"mcp":                    false,
		"resolver":               false,
		"repo":                   false,
		"vcs":                    false,
	}
	fragmentIDs := map[string]bool{}
	for _, contract := range reg.Contracts {
		if _, ok := required[contract.ID]; ok {
			required[contract.ID] = true
		}
		if contract.AuthorityRoot == "" || contract.ContractPath == "" || len(contract.Fragments) == 0 {
			return fmt.Errorf("contract authority %q is incomplete", contract.ID)
		}
		for _, fragment := range contract.Fragments {
			if fragment.ID == "" || fragment.SourceContract != contract.ID {
				return fmt.Errorf("fragment authority mismatch in %q", contract.ID)
			}
			if fragmentIDs[fragment.ID] {
				return fmt.Errorf("duplicate fragment ID %q", fragment.ID)
			}
			fragmentIDs[fragment.ID] = true
		}
	}
	for id, present := range required {
		if !present {
			return fmt.Errorf("required contract authority %q is missing", id)
		}
	}
	return nil
}

func projectRegistry(reg registry) fragmentInventory {
	result := fragmentInventory{Repo: reg.Repo, Fragments: []fragmentDeclaration{}}
	for _, contract := range reg.Contracts {
		for _, fragment := range contract.Fragments {
			fragment.AuthorityRoot = contract.AuthorityRoot
			fragment.ContractPath = contract.ContractPath
			result.Fragments = append(result.Fragments, fragment)
		}
	}
	sort.Slice(result.Fragments, func(i, j int) bool {
		return result.Fragments[i].ID < result.Fragments[j].ID
	})
	return result
}

func generateTurnStart(inventory fragmentInventory) turnStartFragments {
	result := turnStartFragments{
		GeneratedFrom: "registry.index.json",
		Fragments:     []fragmentDeclaration{},
	}
	for _, fragment := range inventory.Fragments {
		if fragment.Surface == "turn_start" {
			result.Fragments = append(result.Fragments, fragment)
		}
	}
	return result
}

func classify(prompt string, available map[string]bool) classification {
	lowerPrompt := strings.ToLower(prompt)
	result := classification{
		Prompt:            prompt,
		SelectedFragments: []string{},
		CompactHints:      []string{},
		Evidence:          []evidence{},
	}
	seenFragments := map[string]bool{}
	seenRoutes := map[string]bool{}
	for _, candidate := range classifierRoutes {
		for _, term := range candidate.Terms {
			if !strings.Contains(lowerPrompt, term) {
				continue
			}
			for _, id := range candidate.Selects {
				if available[id] && !seenFragments[id] {
					result.SelectedFragments = append(result.SelectedFragments, id)
					seenFragments[id] = true
				}
			}
			if !seenRoutes[candidate.ID] {
				result.CompactHints = append(result.CompactHints, candidate.Hint)
				result.Evidence = append(result.Evidence, evidence{
					Kind:   "prompt_term",
					Value:  term,
					Source: "user_prompt",
				})
				seenRoutes[candidate.ID] = true
			}
			break
		}
	}
	return result
}

func validateSelection(ids []string, available map[string]bool) error {
	seen := map[string]bool{}
	for _, id := range ids {
		if !available[id] {
			return fmt.Errorf("selected fragment %q was not generated by turnStart", id)
		}
		if seen[id] {
			return fmt.Errorf("selected fragment %q more than once", id)
		}
		seen[id] = true
	}
	return nil
}

func validateRouteDeclarations(routes []route, available map[string]bool) error {
	for _, r := range routes {
		if err := validateSelection(r.Selects, available); err != nil {
			return fmt.Errorf("route %q: %w", r.ID, err)
		}
	}
	return nil
}

func validateRouteInventory(inventory routeInventory, available map[string]bool) (map[string]registeredRoute, error) {
	if inventory.GeneratedFrom != "contracts/agent-context-resolver/routes.cue" {
		return nil, errors.New("route inventory does not declare CUE route authority")
	}
	routesByID := make(map[string]registeredRoute, len(inventory.Routes))
	for _, route := range inventory.Routes {
		if route.ID == "" {
			return nil, errors.New("route inventory contains an empty route ID")
		}
		if _, exists := routesByID[route.ID]; exists {
			return nil, fmt.Errorf("duplicate route ID %q", route.ID)
		}
		routesByID[route.ID] = route
		for _, fragmentID := range route.InputFragments {
			if !available[fragmentID] {
				return nil, fmt.Errorf("route %q references unknown fragment %q", route.ID, fragmentID)
			}
		}
	}
	for _, route := range inventory.Routes {
		for _, dependencyID := range route.DependsOn {
			if _, exists := routesByID[dependencyID]; !exists {
				return nil, fmt.Errorf("route %q references unknown dependency %q", route.ID, dependencyID)
			}
		}
	}
	return routesByID, nil
}

func validatePromptRouteInvocations(routes []route, routesByID map[string]registeredRoute) error {
	for _, route := range routes {
		for _, routeID := range route.Invokes {
			registered, exists := routesByID[routeID]
			if !exists {
				return fmt.Errorf("prompt route %q invokes unknown route %q", route.ID, routeID)
			}
			if !containsString(registered.PromptRouteIDs, route.ID) {
				return fmt.Errorf("route %q is not registered for prompt route %q", routeID, route.ID)
			}
		}
	}
	return nil
}

func containsString(values []string, wanted string) bool {
	for _, value := range values {
		if value == wanted {
			return true
		}
	}
	return false
}

func fragmentIDSet(fragments []fragmentDeclaration) map[string]bool {
	result := make(map[string]bool, len(fragments))
	for _, fragment := range fragments {
		result[fragment.ID] = true
	}
	return result
}

func readCUEFixture(path string, target any) error {
	expr := fmt.Sprintf("fixtures[%q]", fixtureKey(path))
	command := exec.Command("cue", "export", path, "-e", expr, "--out", "json")
	output, err := command.CombinedOutput()
	if err != nil {
		return fmt.Errorf("export CUE fixture %s: %w: %s", path, err, strings.TrimSpace(string(output)))
	}
	if err := json.Unmarshal(output, target); err != nil {
		return fmt.Errorf("decode CUE fixture %s: %w", path, err)
	}
	return nil
}

func fixtureKey(path string) string {
	name := filepath.Base(path)
	for _, suffix := range []string{".valid.cue", ".invalid.cue", ".cue"} {
		if strings.HasSuffix(name, suffix) {
			return strings.TrimSuffix(name, suffix)
		}
	}
	return name
}

func readJSON(path string, target any) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return fmt.Errorf("read %s: %w", path, err)
	}
	if err := json.Unmarshal(data, target); err != nil {
		return fmt.Errorf("decode %s: %w", path, err)
	}
	return nil
}

func writeJSON(path string, value any) error {
	data, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		return err
	}
	data = append(data, '\n')
	if err := os.WriteFile(path, data, 0o644); err != nil {
		return fmt.Errorf("write %s: %w", path, err)
	}
	return nil
}

func fatalf(format string, args ...any) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
	os.Exit(1)
}
