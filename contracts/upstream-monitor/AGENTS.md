# Upstream Monitor

This tree defines spec-centric operational intel loops for upstream source monitoring inside the reflective transition factory authority surface.

## Doctrine

The monitor is a closed feedback control system.

```text
Z0 Instruction / Dead-Drop
Z1 Toolkit / Gray-Space
Z2 Hot-Box Acquisition
Z3 Semantic Compute
Z4 Output / Ledger
```

Each zone must declare:

```text
input
transform
output
eval
error signal
control action
next_state
```

## Authority

Local specs, CUE contracts, AGENTS files, and loop-local templates are authority.

Upstream repositories are evidence only.

This migrated surface belongs under:

```text
contracts/factory/upstream-monitor/
```

Do not treat the prior `fatb4f/dotfiles` location as authority after migration.

## Invariant

Inference is allowed only inside semantic compute nodes.

Operations are allowed only through declared Gray-Space or Output artifacts.

Every output signal must be consumed by a declared next-state transition or terminate as:

```text
terminal_success
terminal_abort
terminal_deferred
coverage_gap
```

## Required behavior

Agents must:

```text
- follow the nearest loop AGENTS.md
- load the explicitly declared AGENTS instruction chain
- preserve signal IDs across zone transitions
- use loop-local input files for scope
- use loop-local output templates for artifacts
- keep mutations inside declared output paths
```

Agents must not:

```text
- infer operational scope from repository layout
- treat upstream evidence as authority
- broaden a loop to another target
- create reports outside the loop output contract
- claim installability/current-state unless admitted by a state contract
- implement semantic classification in scripts unless explicitly admitted
```
