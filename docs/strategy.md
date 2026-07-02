# Project Strategy

## Working model

This repository follows the same operating pattern that worked well in project 1:

- small approved phases,
- short top-level `README.md`,
- operational details in focused docs,
- one reproducibility checkpoint script only after a phase is implemented, verified, documented, and approved.

## Recommended phase decomposition

1. Bootstrap the repository, document scope, and define the target architecture.
2. Define the SUMO data-generation plan and canonical schemas for Toulouse.
3. Bring up the base Docker environment for Kafka, Spark, Flink, and helper containers.
4. Implement the file-to-Kafka producer and verify topic ingestion.
5. Implement Spark Structured Streaming analytics.
6. Implement Flink analytics with matching semantics.
7. Implement the result consumer and map-oriented presentation layer.
8. Run performance experiments and generate reports.
9. Finalize the Beamer presentation and submission artifacts.

## Reusable lessons from project 1

- Keep architecture decisions explicit early.
- Separate infrastructure docs from app behavior docs.
- Preserve fair-comparison rules before coding the benchmark layer.
- Treat reproducibility scripts as phase checkpoints, not scratchpads.

## Fixed context

- City selection is fixed: Toulouse, France.
- Initial Toulouse spatial entity reference is documented in `docs/spatial-entities.md` and `data/reference/toulouse_spatial_entities.geojson`; it contains OSM polygons for areas, a station point, and multiline road corridors.
- SUMO is not containerized for now; data generation will be a local one-shot script in the SUMO phase.

## Open decisions

- Kafka topic design needs to be fixed during the data/schema phase.
- Streaming implementations must use equivalent spatial matching semantics over the same GeoJSON reference.
- We need to confirm the final image choices for Kafka and Flink if BDE components are unavailable there.

## Recommended next phase

The next approved phase should settle the event schemas and the initial Docker topology before any application code is written.
