# Setup Notes

## Repository status on March 10, 2026

Available locally:

- `docker compose`
- `python3`
- `java`
- `sumo`

## Bootstrap decisions

- Keep the root clean and high-level.
- Track architecture and operational decisions in `docs/`.
- Keep the presentation in Beamer under `slides/`.
- Avoid adding checkpoint scripts before a phase is fully implemented and approved.
- Selected city for the SUMO phase: Toulouse, France.
- SUMO will not be containerized for now. The SUMO phase should use a one-shot local generation script and document the exact command and outputs.

## Expected near-term repository layout

Planned areas:

- `docs/` for architecture, setup, and per-phase operational notes
- `slides/` for the Beamer presentation
- `docker/` for compose-related support files
- `scripts/` or `apps/` for producer, consumer, and analytics code
- `automation/` for approved phase checkpoints only

## Next setup tasks

1. Decide the initial Docker topology and image sources.
2. Define canonical schemas for Kafka topics and downstream outputs.
3. Implement the local one-shot SUMO data generation script.
4. Validate that the local SUMO network covers the Toulouse OSM geometries in `data/reference/toulouse_spatial_entities.geojson`.
