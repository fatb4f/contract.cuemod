package main

import (
	"context"
	"fmt"
	"os"

	mcpadapter "github.com/fatb4f/contract.cuemod/internal/adapters/mcp"
	acr "github.com/fatb4f/contract.cuemod/internal/contracts/agentcontextresolver"
	"github.com/fatb4f/contract.cuemod/internal/cueengine"
)

func main() {
	if err := run(context.Background(), os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run(ctx context.Context, args []string) error {
	repoRoot, err := os.Getwd()
	if err != nil {
		return err
	}
	resolver := acr.Resolver{Engine: cueengine.Engine{RepoRoot: repoRoot}}
	if len(args) == 2 && args[0] == "serve" && args[1] == "mcp" {
		return mcpadapter.Server{Resolver: resolver}.Serve(ctx, os.Stdin, os.Stdout)
	}
	if len(args) < 2 || args[0] != "acr" {
		return fmt.Errorf("usage: contractctl acr <inventory|resolve-prompt|plan-route|validate|export> [--input input.json] [--target runtime-projection] | contractctl serve mcp")
	}

	var out []byte
	switch args[1] {
	case "inventory":
		out, err = resolver.Inventory(ctx)
	case "resolve-prompt":
		input, readErr := readInput(args[2:])
		if readErr != nil {
			return readErr
		}
		out, err = resolver.ResolvePrompt(ctx, input)
	case "plan-route":
		input, readErr := readInput(args[2:])
		if readErr != nil {
			return readErr
		}
		out, err = resolver.PlanRoute(ctx, input)
	case "validate":
		out, err = resolver.Validate(ctx)
		if err == nil && len(out) == 0 {
			out = []byte("ok\n")
		}
	case "export":
		if !hasTarget(args[2:], "runtime-projection") {
			return fmt.Errorf("export requires --target runtime-projection")
		}
		out, err = resolver.ExportRuntimeProjection(ctx)
	default:
		return fmt.Errorf("unknown acr command %q", args[1])
	}
	if err != nil {
		return err
	}
	_, err = os.Stdout.Write(out)
	return err
}

func readInput(args []string) ([]byte, error) {
	for i := 0; i < len(args)-1; i++ {
		if args[i] == "--input" {
			return os.ReadFile(args[i+1])
		}
	}
	return nil, nil
}

func hasTarget(args []string, target string) bool {
	for i := 0; i < len(args)-1; i++ {
		if args[i] == "--target" && args[i+1] == target {
			return true
		}
	}
	return false
}
