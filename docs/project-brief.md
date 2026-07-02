# Project Brief

Source: `../BDS - Project2.pdf`

## Required outcomes

1. Generate one or more large datasets (`~1 GB`) with the SUMO simulator for a unique city.
2. Use both SUMO emission output and FCD output.
3. Collect important city spatial entities from OSM or Google Maps.
4. Build a helper producer that reads records from file(s) and publishes them to Kafka topic(s).
5. Implement two stream-processing applications:
   - Apache Spark Structured Streaming
   - Apache Flink
6. Support tumbling and sliding windows, chosen via input arguments.
7. Compute in near real time:
   - pollution trends around selected spatial entities,
   - traffic volume near streets/areas/entities.
8. Send analysis results to new Kafka topic(s) and consume/display them, preferably on a Folium-based map.
9. Benchmark Spark and Flink Docker clusters on the local machine and compare performance.
10. Prepare a presentation and publish the project code.

## Immediate implications

- This is a streaming project, not a batch analytics project.
- The repo should be organized around a reusable streaming pipeline and fair Spark/Flink comparison.
- Selected city: Toulouse, France.
- The selected city must be used for the SUMO scenario, spatial entity collection, and downstream analytics examples.
- Initial spatial entity reference: `docs/spatial-entities.md`.
- Machine-readable reference snapshot: `data/reference/toulouse_spatial_entities.geojson`.
- Canonical event contracts: `docs/event-schemas.md`.
- Initial Docker topology: `docs/docker-topology.md`.
