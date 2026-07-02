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

Recommended output topics:

- `analytics.pollution`
- `analytics.traffic`

Recommended input topics:

- `mobility.fcd`
- `mobility.emissions`

## Fair-comparison rule

Spark and Flink should consume equivalent Kafka inputs, use the same window definitions, and emit comparable result schemas so the performance comparison measures the engine choice rather than different business logic.
