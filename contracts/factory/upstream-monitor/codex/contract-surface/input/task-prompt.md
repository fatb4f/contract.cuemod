Use the GitHub App adapter to fetch the upstream-monitor loop entrypoint from the owned repository.

Repository:

```text
fatb4f/contract.cuemod
```

Ref policy:

```text
Use branch `factory/reflective-transition-factory` unless the task explicitly provides a commit SHA.
Record the resolved commit SHA before proceeding.
```

Entrypoint:

```text
contracts/factory/upstream-monitor/codex/contract-surface/AGENTS.md
```

Read that file first. Follow its declared instruction chain exactly.

Do not infer operational scope from repository layout.

Do not use ChatGPT project files unless GitHub access is unavailable. Project files are fallback only. If GitHub access is unavailable, stop and report a Z0 adapter failure.

This task emits the Z0 signal:

```text
signal_id: loop_bootstrap_request
target_repo: fatb4f/contract.cuemod
target_ref: factory/reflective-transition-factory
entrypoint: contracts/factory/upstream-monitor/codex/contract-surface/AGENTS.md
adapter: github_app
fallback: project_files_only_if_github_unavailable
```

After loading the entrypoint, proceed only if Z1 accepts the same `signal_id`.

Forbidden at Z0:

```text
- do not inspect upstream openai/codex yet
- do not create reports
- do not create or update GitHub issues
- do not write repo files
- do not broaden scope beyond the declared loop
```
