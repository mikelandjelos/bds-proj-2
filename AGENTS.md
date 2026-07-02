# AGENTS.md

## Scope

These rules apply only to this repository: `bds-proj-2`.

## Project context

- Course: Big Data Systems project.
- Topic: Big Mobility Data Stream Analytics.
- Objective: build the project in atomic, approval-based phases.

## Working mode

- Work in small atomic steps.
- Do not continue to the next phase without explicit user approval.
- Prefer implementing and verifying one concrete deliverable per step.

## Reproducibility checkpoint policy

- After each phase is fully completed and approved, create exactly one checkpoint script in `automation/`.
- Script naming convention: `phase<N>_<semantic_name>.sh` (for example `phase2_preprocessing.sh`).
- A phase checkpoint script is created only when:
  - implementation for that phase is working,
  - verification commands pass,
  - documentation is updated for that phase.
- The script must reproduce the completed phase state without requiring users to remember long command sequences.

## Infrastructure rules

- Infrastructure must be Docker-first.
- Prefer `docker compose` orchestration.
- Use [`big-data-europe`](https://github.com/big-data-europe/) components where they fit naturally (especially Hadoop/Spark); if a required service is not realistically covered by BDE, document the alternative and confirm with the user before locking it in.
- No persistent docker volumes unless explicitly approved.
- Read-only bind mounts for input data are allowed.

## Project-specific delivery rules

- Before the SUMO phase starts, record the selected city in the docs.
- SUMO data generation must include both emission output and FCD output.
- Significant spatial entities must be collected from OSM or Google Maps and documented with enough metadata for downstream analysis.
- The Spark Structured Streaming and Flink applications must implement equivalent analytical logic over equivalent Kafka inputs so the comparison stays fair.
- Benchmarking must compare the two streaming implementations on the same workload definitions and window configurations.

## Documentation & context updating rules

- Keep `README.md` short and high-level.
- Put operational details into focused docs under `docs/`.
- Update docs immediately when workflow changes.
- Maintain the project presentation as a Beamer deck under `slides/`; keep it selective and implementation-oriented rather than exhaustive.

## Safety and change control

- Avoid destructive commands unless explicitly requested.
- Do not revert user changes unless requested.
- If unexpected repo changes appear, stop and ask before proceeding.
