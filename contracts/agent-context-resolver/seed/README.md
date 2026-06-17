# Agent Context Resolver Seed

This directory is a self-contained seed for importing the agent-context
resolver authority chain into `contract.cuemod` with sparse checkout.

The authority flow is:

```text
contract/registry.cue
  -> generated/registry.index.json
  -> contract/projection.cue
  -> generated/fragment_inventory.json
  -> turnStart producer
  -> generated/turn_start_fragments.json
  -> UserPromptSubmit classifier
  -> generated/prompt_routes.json
```

`UserPromptSubmit` only selects IDs present in the generated turn-start
universe. It cannot emit the registry, assemble context bodies, or promote MCP
or tool output into implied context.

## Generate

```bash
./scripts/generate.sh
```

Generation first exports the concrete CUE registry, then the adapter consumes
that JSON index. CUE remains the registry authority; Go implements the native
hook/generator boundary.

## Validate

```bash
./scripts/validate.sh
```

Validation checks the CUE model, deterministic generation, generated artifact
semantics, the positive classification fixture, and every negative fixture.

## Sparse Import

```bash
git sparse-checkout init --cone
git sparse-checkout set contracts/agent-context-resolver/seed
```

The imported directory has no dependency on files outside this seed.
