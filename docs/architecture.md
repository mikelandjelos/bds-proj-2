# Target Architecture

## Pipeline

```text
SUMO outputs (FCD, emissions)
  -> file-to-Kafka producer
  -> Kafka source topics
  -> Spark Structured Streaming analytics
  -> Flink analytics
  -> Kafka result topics
  -> consumer / map visualization
```

## Layer model

```text
+---------------------------+
| Reference layer           |
| OSM / Google Maps entities|
+---------------------------+

+---------------------------+
| Data generation layer     |
| SUMO scenario + outputs   |
+---------------------------+

+---------------------------+
| Streaming transport layer |
| Kafka + helper producer   |
+---------------------------+

+---------------------------+
| Processing layer          |
| Spark SS and Flink apps   |
+---------------------------+

+---------------------------+
| Presentation layer        |
| consumer + Folium/map UI  |
+---------------------------+
```

## Analytical outputs

Canonical output topics:

- `analytics.pollution`
- `analytics.traffic`

Canonical input topics:

- `mobility.fcd`
- `mobility.emissions`

The event contracts are documented in `docs/event-schemas.md`.

## Docker topology

The first infrastructure implementation should use the service topology documented in `docs/docker-topology.md`:

- Kafka in single-node KRaft mode,
- Spark standalone master and worker,
- Flink session cluster with JobManager and TaskManager,
- on-demand producer and consumer/map helper containers.

The same Compose definition must support three run modes: `full`, `spark-only`, and `flink-only`. The engine-specific modes are required for fair benchmarking so the inactive engine does not consume local CPU or memory.

No persistent Docker volumes are approved for the initial topology.

Operational commands for the Compose stack are documented in `docs/operations-compose.md`.

## Fair-comparison rule

Spark and Flink should consume equivalent Kafka inputs, use the same window definitions, and emit comparable result schemas so the performance comparison measures the engine choice rather than different business logic.
