# Legacy inputs

`workspace.cue` is the earlier dotfiles-domain routing registry.

`workspace.session.json` is the older JSON Schema for the phase-1 terminal workflow.

The refined contract keeps their useful constraints but changes the authority boundary:

```text
contract.cuemod owns global declarations.
dotfiles implements host/adapters.
project contexts are global objects consumed by adapters.
```
