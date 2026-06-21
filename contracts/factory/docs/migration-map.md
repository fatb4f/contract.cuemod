# Factory migration map

This document classifies every remaining root in the factory branch before any destructive migration, quarantine, or deletion.

Allowed classifications:

- keep-active
- migrate-factory
- quarantine-legacy
- delete

No root survives because it existed before. Every retained artifact must support the reflective transition factory.

| Source path | Current role | Classification | Target path | Action | Blocking dependency | Notes |
|---|---|---|---|---|---|---|
| .github/ | repo process | keep-active | .github/ | keep | none | Issue templates and repo workflow metadata. |
| README.md | repo entrypoint | migrate-factory | README.md | rewrite | factory surface stable | Should describe transition-factory branch, not old authority host. |
| go.mod | Go tooling module | keep-active | go.mod | keep temporarily | adapter audit | Process/tooling only; not semantic authority. |
| justfile | control adapter | keep-active | justfile | keep temporarily | command audit | Should route factory checks only. |
| cmd/ | Go CLI commands | keep-active | cmd/ | audit | adapter audit | Keep only commands serving factory workflow. |
| internal/ | Go internals | keep-active | internal/ | audit | adapter audit | Keep only internals backing active factory adapters. |
| fixtures/ | legacy fixture root | migrate-factory / quarantine-legacy | contracts/factory/fixtures/ or migration/legacy/fixtures/ | classify children | fixture audit | No top-level fixture root in final surface. |
| generated/ | legacy generated root | migrate-factory / quarantine-legacy | contracts/factory/generated/ or migration/legacy/generated/ | classify children | projection audit | No top-level generated root in final surface. |
| providers/ | old provider model | quarantine-legacy | migration/legacy/providers/ | move after audit | worker aperture audit | Provider model is superseded by worker aperture model. |
| projections/ | old projection root | migrate-factory / quarantine-legacy | contracts/factory/generated/projections/ or migration/legacy/projections/ | classify children | projection audit | Factory projections must be post-admission artifacts. |
| adapters/ | adapter implementations | keep-active / quarantine-legacy | contracts/factory/adapters/ or migration/legacy/adapters/ | classify children | adapter audit | Raw git adapter likely legacy unless rewritten as worker aperture. |
| docs/ | mixed docs | migrate-factory / quarantine-legacy | contracts/factory/docs/ or migration/legacy/docs/ | classify children | doc audit | Active docs must describe factory model. |
| test/ | old validation scripts | migrate-factory / quarantine-legacy | contracts/factory/checks/ or migration/legacy/test/ | classify children | validation audit | Checks should target factory gates. |
| contracts/factory/ | target factory surface | keep-active | contracts/factory/ | keep | none | Dominant contract surface. |
| contracts/object/ | object vocabulary | migrate-factory | contracts/factory/object/ | move/merge | import audit | Avoid parallel object roots. |
| contracts/transition-factory/ | old transition factory root | migrate-factory | contracts/factory/transition/ | move/merge | import audit | Collapse into factory-local module. |
| contracts/workers/ | worker vocabulary | migrate-factory | contracts/factory/workers/ | move/merge | worker audit | Worker apertures belong to factory surface. |
| contracts/agent-runtime/ | runtime input surface | migrate-factory | contracts/factory/runtime/ | move/merge | resolver/runtime audit | Runtime is input to transition packet. |
| contracts/agent-context-resolver/ | resolver input surface | migrate-factory | contracts/factory/resolver/ | move/merge | resolver audit | Resolver selects objects/workers/evidence. |
| contracts/repo/ | old repo authority | quarantine-legacy | migration/legacy/contracts/repo/ | move | none | Not active factory authority. |
| contracts/vcs/ | old raw VCS model | quarantine-legacy | migration/legacy/contracts/vcs/ | move | none | GitButler worker should be VCS aperture. |
| contracts/providers/ | old provider model | quarantine-legacy | migration/legacy/contracts/providers/ | move | none | Superseded by worker aperture model. |
| contracts/agent-skill/ | plugin/skill legacy | quarantine-legacy | migration/legacy/contracts/agent-skill/ | move | plugin audit | Not core factory surface. |
| contracts/graph/ | old authority graph | quarantine-legacy | migration/legacy/contracts/graph/ | move after audit | graph audit | Retain only if converted to bounded evidence model. |
| contracts/protocols/ | protocol vocabulary | classify | TBD | audit | protocol audit | Could be transport support or legacy. |
| contracts/assertions/ | assertion vocabulary | migrate-factory | contracts/factory/assertions/ | move/merge | gate audit | Assertions are gate authority. |
| contracts/validation/ | validation vocabulary | migrate-factory | contracts/factory/validation/ | move/merge | gate audit | Keep only validation tied to factory gates. |
| contracts/context/ | context vocabulary | classify | TBD | audit | resolver audit | Likely resolver/runtime migration source. |
| contracts/adapters/ | adapter vocabulary | migrate-factory | contracts/factory/adapters/ | reduce/move | adapter audit | Must become worker aperture boundary vocabulary. |
| contracts/registry.cue | old root registry | delete / migrate-factory | contracts/factory/registry.cue or none | classify | registry audit | No root contract authority registry. |
