# Compose Operations

## Purpose

This document records the commands for running the current Docker Compose infrastructure. The stack is infrastructure-only: Kafka, topic initialization, Spark standalone containers, and Flink session-cluster containers.

No persistent Docker volumes are used. Kafka data is ephemeral and disappears after containers are removed.

## Run Modes

Full development mode:

```bash
docker compose --profile spark --profile flink up -d
```

Spark-only benchmark mode:

```bash
docker compose --profile spark up -d
```

Flink-only benchmark mode:

```bash
docker compose --profile flink up -d
```

The engine-specific modes are used for fair benchmarking so the inactive engine does not consume local CPU or memory.

The current local baseline assumes a 16-vCPU host and allocates 8 execution slots/cores to the active engine:

- Spark worker: `SPARK_WORKER_CORES=8`
- Flink worker: `FLINK_NUM_TASK_SLOTS=8`

## Status And Logs

Show running containers:

```bash
docker compose ps
```

Follow Kafka logs:

```bash
docker compose logs -f kafka
```

Follow all logs for the selected mode:

```bash
docker compose logs -f
```

## Kafka Topics

List topics:

```bash
docker compose exec kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server kafka:19092 \
  --list
```

Expected topics:

```text
analytics.pollution
analytics.traffic
mobility.emissions
mobility.fcd
```

Describe a topic:

```bash
docker compose exec kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server kafka:19092 \
  --describe \
  --topic mobility.fcd
```

## Web UIs

When the relevant profile is running:

- Spark master UI: `http://localhost:8080`
- Spark worker UI: `http://localhost:8081`
- Flink UI: `http://localhost:8082`

## Shutdown

Stop and remove containers for the active mode:

```bash
docker compose --profile spark --profile flink down
```

The command above is safe for all modes because profiles only affect which optional services are included. No named volumes are removed because the stack does not define any.

## Static Validation

Validate Compose syntax and profile expansion:

```bash
docker compose config
docker compose --profile spark config
docker compose --profile flink config
docker compose --profile spark --profile flink config
```

## Phase Checkpoint

Run the approved phase 1 checkpoint:

```bash
automation/phase1_docker_topology.sh
```

The checkpoint validates all Compose profile expansions, starts `full`, `spark-only`, and `flink-only` modes, checks Kafka topic initialization, checks the 8-core Spark worker baseline, checks the 8-slot Flink worker baseline, and shuts the stack down.
