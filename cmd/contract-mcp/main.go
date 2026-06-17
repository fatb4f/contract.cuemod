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
	repoRoot, err := os.Getwd()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	resolver := acr.Resolver{Engine: cueengine.Engine{RepoRoot: repoRoot}}
	if err := (mcpadapter.Server{Resolver: resolver}).Serve(context.Background(), os.Stdin, os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
