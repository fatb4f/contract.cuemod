# Legacy vb-reference workflow

`test/vb-reference-workflow.sh` and the `contracts/vb-reference` authority were retired from the active validation surface.

The vb-reference workflow represented an older proposed virtual-branch acceptance harness. It remains legacy evidence only; current VCS workflow assertions should be modeled through the GitButler-oriented repo/VCS contracts, especially `contracts/repo/vcs_workflow.cue`, `contracts/repo/workflow_routes.cue`, `contracts/repo/adapter_routes.cue`, and the `fixtures/vcs` assertion fixtures.

CUE assertions are the current authority. Shell tests are derived evaluator shims only.
