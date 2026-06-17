package cueengine

import (
	"bytes"
	"context"
	"fmt"
	"os/exec"
)

type Engine struct {
	RepoRoot string
}

func (e Engine) Export(ctx context.Context, pkg, expr string) ([]byte, error) {
	args := []string{"export", pkg, "--force", "--out", "json"}
	if expr != "" {
		args = append(args, "-e", expr)
	}
	return e.run(ctx, args...)
}

func (e Engine) Vet(ctx context.Context, pkg string) ([]byte, error) {
	return e.run(ctx, "vet", pkg)
}

func (e Engine) Eval(ctx context.Context, pkg, expr string) ([]byte, error) {
	args := []string{"eval", pkg, "-c"}
	if expr != "" {
		args = append(args, "-e", expr)
	}
	return e.run(ctx, args...)
}

func (e Engine) run(ctx context.Context, args ...string) ([]byte, error) {
	cmd := exec.CommandContext(ctx, "cue", args...)
	cmd.Dir = e.RepoRoot
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("cue %v: %w: %s", args, err, stderr.String())
	}
	return out, nil
}
