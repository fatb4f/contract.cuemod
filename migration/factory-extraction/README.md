# Factory Extraction Provenance

The reflective transition factory authority moved to `fatb4f/factory`.

Migration umbrella: `#66`

Final source-repo migration issues:

- `#67` sealed the factory extraction surface.
- `#68` admitted the extraction transition packet.
- `#69` seeded `fatb4f/factory`.
- `#70` rebound module authority in `fatb4f/factory`.
- `#71` validated parity in `fatb4f/factory`.
- `#72` detached source authority from this repository.
- `#73` handed future review and upstream-monitor output to `fatb4f/factory`.

This repository must not recreate `contracts/factory/**` as an active authority
root. Future factory work belongs in `fatb4f/factory`.
