# Lint toolchain contract

## Boundary

```text
CUE
→ declares project language/toolchain policy

shell-wrap
→ materializes declared commands into executable adapters

just
→ exposes stable recipes: lint, fmt, check, test, build

WezTerm
→ runs `just --choose` and owns the visible process/output surface
```

Do not put language branching in WezTerm, xplr, or Neovim.

## Preferred multi-language lint path

For projects with a `.pre-commit-config.yaml`, use it as the local hook/toolchain manifest:

```just
lint:
  shell-wrap lint
```

The generated `shell-wrap lint` may simply run:

```bash
pre-commit run --all-files
```

CUE should declare that policy explicitly:

```cue
toolchain: {
  languages: ["lua", "shell", "cue", "yaml"]
  lint: {
    backend: "pre-commit"
    configPath: ".pre-commit-config.yaml"
    allFiles: true
    command: {
      name: "lint"
      argv: ["pre-commit", "run", "--all-files"]
      cwd: root
    }
  }
}
```

## Just should not parse YAML

`just` should not parse `.pre-commit-config.yaml` to infer tools. That would make `just` a second contract/runtime parser.

Use one of these models instead:

1. **pre-commit as linter runner**
   - `.pre-commit-config.yaml` declares hooks.
   - `shell-wrap lint` runs `pre-commit run --all-files`.
   - `just lint` calls `shell-wrap lint`.

2. **CUE as toolchain declaration**
   - CUE declares direct lint steps.
   - `shell-wrap` generates the adapter.
   - `just lint` calls `shell-wrap lint`.

3. **Hybrid**
   - CUE declares `backend: "pre-commit"` and the pre-commit config path.
   - `shell-wrap` generates a stable adapter that invokes pre-commit.
   - `.pre-commit-config.yaml` remains the hook manifest.

## Stable project justfile

```just
default:
  just --choose

lint:
  shell-wrap lint

fmt:
  shell-wrap fmt

check:
  just lint
  just test
  just build

test:
  shell-wrap test

build:
  shell-wrap build
```

The project recipe names stay stable across Lua, Shell, CUE, Go, TypeScript, Python, Rust, etc.
The adapter implementation varies by CUE projection.
