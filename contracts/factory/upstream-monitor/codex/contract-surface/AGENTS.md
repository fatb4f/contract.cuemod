# Codex Contract-Surface Loop

## Instruction chain

Before acting, load and apply these files in order:

```text
contracts/factory/upstream-monitor/AGENTS.md
contracts/factory/upstream-monitor/codex/AGENTS.md
contracts/factory/upstream-monitor/codex/contract-surface/AGENTS.md
```

This file is the loop entrypoint for the scheduled ChatGPT task.

## Accepted input signal

This loop accepts only:

```text
signal_id: loop_bootstrap_request
target_repo: fatb4f/contract.cuemod
entrypoint: contracts/factory/upstream-monitor/codex/contract-surface/AGENTS.md
adapter: github_app
```

If the signal ID differs, stop and report `input_invalid`.

## Mission setpoint

Maintain a versioned local impact view of upstream `openai/codex` changes that intersect the declared local Codex contract surface.

This loop is spec-centric. It defines state transitions, artifact contracts, and issue/update shapes before implementation behavior.

## Contained toolkit

This loop is a contained toolkit. Its roles are explicit and non-interchangeable:

```text
acquisition -> collect declared evidence only
inference   -> classify and reduce candidates through CUE constraints
formatting  -> render admitted impacts into loop-local shapes
output      -> mutate only declared ledger/report/issue paths after admission
```

Variable upstream surfaces are not operational scope by themselves. They are admitted only through loop-local CUE filters and constraints.

## Initial gate

The first implementation gate is next-state transition closure.

Before adding acquisition, adapters, report rendering, issue posting, or scripts, prove:

```text
Z0.output.signal_id == Z1.input.signal_id
```

and define the complete closed-loop next-state graph:

```text
Z0 -> Z1 -> Z2 -> Z3 -> Z4 -> terminal_success
```

with failure transitions for:

```text
terminal_abort
terminal_deferred
coverage_gap
```

## Forbidden for the initial gate

Do not:

```text
- inspect upstream openai/codex
- run acquisition
- create reports
- create or update GitHub issues
- write ledger artifacts
- implement semantic classifiers outside CUE-admitted inference
- monitor non-Codex upstreams
```

## Required next output

Produce or update the CUE specs that define:

```text
#Zone
#ComputeNode
#Signal
#Transition
#EvalGate
#ControlAction
#FailureState
#ToolkitRole
#LoopToolkit
#ToolkitNode
#VariableSurface
```

The first proof target is signal continuity and next-state closure, not upstream monitoring.
