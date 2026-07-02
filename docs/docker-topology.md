# Docker Topology

## Purpose

This document records the initial Docker-first topology for the project. The topology is implemented in `docker-compose.yml`; operational commands are documented in `docs/operations-compose.md`.

The topology uses ephemeral containers and read-only bind mounts for reference/input data. No persistent Docker volumes are approved for this project phase.

## Implemented Services

| Service | Role | Initial count | Ports for local use | State policy |
| --- | --- | --- | --- | --- |
| `kafka` | Kafka broker in KRaft mode | 1 | `9092` | Ephemeral container filesystem. |
| `kafka-init` | One-shot topic creation container | 1 per stack startup | none | Exits after ensuring required topics exist. |
| `spark-master` | Spark standalone master | 1 | `7077`, `8080` | Ephemeral. |
| `spark-worker-1` | Spark worker with 8 worker cores | 1 | `8081` | Ephemeral. |
| `flink-master` | Flink master / JobManager role | 1 | host `8082` mapped to container UI port | Ephemeral. |
| `flink-worker-1` | Flink worker / TaskManager role with 8 task slots | 1 | none by default | Ephemeral. |

The first implementation keeps one worker per engine. Benchmark phases can scale worker counts only after the single-worker baseline is working.

Future app containers:

| Service | Role | Initial count | Ports for local use | State policy |
| --- | --- | --- | --- | --- |
| `producer` | File-to-Kafka helper app | 1 on demand | none | Read-only access to generated SUMO files. |
| `consumer-map` | Result consumer / map app | 1 on demand | app port chosen later | Ephemeral. |

## Required Run Modes

The Compose implementation supports three explicit run modes:

| Mode | Purpose | Services |
| --- | --- | --- |
| `full` | Development and end-to-end smoke testing with both engines available. | Kafka, topic init, Spark master/worker, Flink master/worker. |
| `spark-only` | Spark benchmark runs without Flink containers consuming CPU or memory. | Kafka, topic init, Spark master/worker. |
| `flink-only` | Flink benchmark runs without Spark containers consuming CPU or memory. | Kafka, topic init, Flink master/worker. |

The Compose implementation uses profiles:

```text
docker compose --profile spark --profile flink up
docker compose --profile spark up
docker compose --profile flink up
```

Kafka and topic initialization are common infrastructure for all three modes. Future producer and consumer/map containers should remain on-demand so benchmark runs can control exactly when data publishing and result collection start.

The `spark-only` and `flink-only` modes are the fair benchmarking modes. They must use the same Kafka input topics, source datasets, spatial reference, window configuration, and host resource assumptions.

## Network

All services share one Compose network: `bds-mobility-net`.

Internal bootstrap addresses:

- Kafka: `kafka:19092`
- Spark: `spark://spark-master:7077`
- Flink JobManager RPC: `flink-master:6123` inside the Docker network

Host-facing ports should avoid conflicts between Spark and Flink web UIs:

- Spark master UI: host `8080`
- Spark worker UI: host `8081`
- Flink JobManager UI: host `8082`
- Kafka client listener: host `9092`

## Bind Mounts

Allowed bind mounts for the first Compose implementation:

| Host path | Container use | Mode |
| --- | --- | --- |
| `data/reference/` | Spatial reference input | read-only |
| future SUMO output directory | Producer input | read-only |
| application source/build artifacts | Development-time app packaging | read-only unless a later build phase needs otherwise |

Persistent named Docker volumes are not allowed unless explicitly approved later.

## Image Source Decisions

| Component | Initial image source | Status | Reasoning |
| --- | --- | --- | --- |
| Spark master/worker | `bde2020/spark-master:3.3.0-hadoop3.3`, `bde2020/spark-worker:3.3.0-hadoop3.3` | selected for Compose draft | Big Data Europe provides a Spark standalone master/worker setup and supported Spark 3.3.0 Hadoop 3.3 tags. |
| Flink JobManager/TaskManager | `bde2020/flink-master:1.14.5-hadoop3.2`, `bde2020/flink-worker:1.14.5-hadoop3.2` | selected for Compose draft | Big Data Europe provides a Flink master/worker setup. If Kafka connector packaging becomes a blocker, switch to official Flink images with an explicit version tag after documenting the change. |
| Kafka | `apache/kafka:4.3.1` | locked for Compose | Big Data Europe does not provide a realistic Kafka component for this project. The Apache image supports KRaft mode and Compose use, so it is the selected non-BDE component. |
| Producer/consumer apps | project-built images | planned | Application containers should be built from local Dockerfiles once app code exists. |

Sources checked:

- Big Data Europe Spark Docker repository: `https://github.com/big-data-europe/docker-spark`
- Big Data Europe Flink Docker repository: `https://github.com/big-data-europe/docker-flink`
- Apache Kafka Docker image: `https://hub.docker.com/r/apache/kafka`
- Apache Flink Docker deployment docs: `https://nightlies.apache.org/flink/flink-docs-master/docs/deployment/resource-providers/standalone/docker/`

## Kafka Runtime Shape

The Kafka deployment is a single-node KRaft broker:

- one container,
- no ZooKeeper,
- plaintext listeners only,
- default replication factor `1`,
- default partitions `3` for local parallelism,
- no persistent log volume in this phase.

Topic creation is handled by the `kafka-init` container. The required topics are defined in `docs/event-schemas.md`.

## Spark Runtime Shape

Spark starts as a standalone cluster:

- one master,
- one worker capped at `8` cores for the initial 16-vCPU local benchmark baseline,
- structured streaming app submitted later via a project-built image or `spark-submit` helper container,
- no Spark history server in the first Compose implementation because it usually implies writable event-log storage.

If benchmarking needs a history server later, add it in the benchmarking phase with explicit storage rules.

## Flink Runtime Shape

Flink starts as a session cluster:

- one BDE Flink master container,
- one BDE Flink worker container,
- `8` task slots for the initial 16-vCPU local benchmark baseline,
- app submitted later via a project-built image or CLI helper.

Flink connector dependencies must be part of the runtime image or job artifact, not manually copied into a running container.

## Compose Implementation Rules

- Use `docker compose`.
- Support `full`, `spark-only`, and `flink-only` run modes from the same Compose definition.
- Do not add persistent volumes.
- Keep generated data outside Docker and mount it read-only into the producer.
- Keep spatial reference data read-only in processing containers.
- Pin all external image tags before the Compose file is committed.
- Make topic names and app environment variables match `docs/event-schemas.md`.
- Keep Spark and Flink resource settings comparable for benchmark runs, and do not run the other engine's containers during engine-specific benchmarks.

The current local benchmark baseline assumes a 16-vCPU host and allocates 8 execution slots/cores to the active engine.

## Open Items For Next Phase

- Decide the exact host directory for generated SUMO outputs.
- Decide whether app containers are Python-first or JVM-first after choosing implementation language for producer and consumers.
