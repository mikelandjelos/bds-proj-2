# Setup Notes

## Repository status on March 10, 2026

Available locally:

- `docker compose`
- `python3`
- `java`
- `pdflatex`

Missing locally:

- `sumo`

## Bootstrap decisions

- Keep the root clean and high-level.
- Track architecture and operational decisions in `docs/`.
- Keep the presentation in Beamer under `slides/`.
- Avoid adding checkpoint scripts before a phase is fully implemented and approved.

## Expected near-term repository layout

Planned areas:

- `docs/` for architecture, setup, and per-phase operational notes
- `slides/` for the Beamer presentation
- `docker/` for compose-related support files
- `scripts/` or `apps/` for producer, consumer, and analytics code
- `automation/` for approved phase checkpoints only

## Next setup tasks

1. Choose and record the project city.
2. Decide the initial Docker topology and image sources.
3. Install or containerize SUMO for reproducible data generation.
4. Define canonical schemas for Kafka topics and downstream outputs.
