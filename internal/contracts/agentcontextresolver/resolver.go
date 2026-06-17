package agentcontextresolver

import (
	"context"

	"github.com/fatb4f/contract.cuemod/internal/cueengine"
)

const Package = "./contracts/agent-context-resolver"

type Resolver struct {
	Engine cueengine.Engine
}

func (r Resolver) Inventory(ctx context.Context) ([]byte, error) {
	return r.Engine.Export(ctx, Package, "routeInventory")
}

func (r Resolver) ResolvePrompt(ctx context.Context, _ []byte) ([]byte, error) {
	return r.Engine.Export(ctx, Package, "promptRoutes")
}

func (r Resolver) PlanRoute(ctx context.Context, _ []byte) ([]byte, error) {
	return r.Engine.Export(ctx, Package, "routeCompilerProof")
}

func (r Resolver) Validate(ctx context.Context) ([]byte, error) {
	return r.Engine.Vet(ctx, Package)
}

func (r Resolver) ExportRuntimeProjection(ctx context.Context) ([]byte, error) {
	return r.Engine.Export(ctx, Package, "routeCompilerProof.runtime")
}
