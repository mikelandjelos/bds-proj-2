# Toulouse Spatial Entity Reference

## Purpose

The streaming jobs need a fixed reference set of Toulouse entities so Spark and Flink can compute equivalent traffic and pollution metrics.

This document records the initial Toulouse reference snapshot used before the Kafka/SUMO implementation phase. The machine-readable snapshot is stored at `data/reference/toulouse_spatial_entities.geojson`.

The snapshot contains stable entity IDs, OSM references, OSM-derived geometries, representative points, and matching thresholds. It is ready to be used as the shared spatial reference by both Spark and Flink.

## Source Policy

- Primary source: OpenStreetMap.
- Lookup tools:
  - Nominatim for seed entity discovery and representative centroid/bounding-box metadata.
  - Overpass for final geometry extraction, especially road corridors made from multiple OSM ways.
- Coordinate system: WGS84 latitude/longitude in source data.
- Processing projection: use a metric projection or geodesic distance for radius matching; do not compute meter distances directly in raw latitude/longitude degrees.
- Attribution: derived datasets must keep OpenStreetMap attribution and ODbL notes.

## Matching Rules

Three spatial matching modes are enough for the first implementation:

- `radius`: match vehicle points to a point within a configured radius.
- `area_buffer`: match vehicle points to an area geometry, optionally buffered by the configured distance.
- `corridor`: match vehicle points to road geometries within a configured buffer.

Recommended default thresholds:

- POI / compact area: `300 m` to `500 m`.
- Airport / large campus: `1000 m`.
- Road corridor: `75 m` from the extracted road geometry.

The same entity IDs and thresholds must be used by both Spark and Flink.

## Reference Snapshot

| Entity ID | Name | Kind | OSM seed | Geometry | Match | Analytics role |
| --- | --- | --- | --- | --- | --- | --- |
| `tls_airport` | Aéroport de Toulouse-Blagnac | aerodrome | `way/368475266` | `Polygon` | area buffer `1000 m` | Airport traffic and emissions hotspot. |
| `tls_matabiau` | Toulouse-Matabiau | railway station | `node/6132514816` | `Point` | radius `500 m` | Main rail station traffic and intermodal congestion. |
| `tls_capitole` | Place du Capitole | square | `relation/11148976` | `Polygon` | area buffer `300 m` | Dense city-center pedestrian/taxi/service traffic zone. |
| `tls_stadium` | Stadium de Toulouse | stadium | `way/534217397` | `Polygon` | area buffer `500 m` | Event-area traffic and episodic congestion. |
| `tls_purpan_hospital` | Hôpital Purpan | hospital | `way/25534637` | `Polygon` | area buffer `500 m` | Sensitive health-area pollution monitoring. |
| `tls_peripherique_ext` | Périphérique Extérieur | motorway corridor | `way/8101480`, `way/277634786`, `way/8599587` | `MultiLineString` | corridor `75 m` | Outer ring traffic volume and emissions. |
| `tls_peripherique_int` | Périphérique Intérieur | motorway corridor | `way/911843811`, `way/14794183`, `way/14774844` | `MultiLineString` | corridor `75 m` | Inner ring traffic volume and emissions. |
| `tls_route_narbonne` | Route de Narbonne | primary/secondary corridor | `way/203119981`, `way/4485466`, `way/26138255` | `MultiLineString` | corridor `75 m` | South Toulouse corridor near Rangueil / university area. |
| `tls_boulevard_strasbourg` | Boulevard de Strasbourg | primary central corridor | `way/5137104`, `way/339883308`, `way/62211498` | `MultiLineString` | corridor `75 m` | Central north-south traffic corridor. |

`tls_matabiau` remains a `Point` because the selected OSM object is a station node. All area entities use OSM polygon geometry, and corridor entities use OSM way geometry grouped as `MultiLineString`.

## OSM Extraction Pattern

For point/area entities, collect the exact OSM object by ID and export the full geometry where available.

For corridors, collect all matching ways in the Toulouse bounding area by stable tags:

```text
name = "Périphérique Extérieur"
name = "Périphérique Intérieur"
name = "Route de Narbonne"
name = "Boulevard de Strasbourg"
```

The extraction output should normalize each entity into:

```json
{
  "entity_id": "tls_capitole",
  "name": "Place du Capitole",
  "kind": "square",
  "match_mode": "area_buffer",
  "buffer_m": 300,
  "osm_refs": ["relation/11148976"],
  "geometry": "GeoJSON geometry"
}
```

## Downstream Metrics

The spatial entity reference should support two equivalent streaming analyses:

- Pollution trend per entity/window:
  - input: SUMO emission stream
  - grouping: `entity_id`, `window_start`, `window_end`
  - metrics: vehicle count, average CO2, average NOx, average PMx, summed fuel where available
- Traffic volume per entity/window:
  - input: SUMO FCD stream
  - grouping: `entity_id`, `window_start`, `window_end`
  - metrics: vehicle count, average speed, stopped/slow vehicle count

Both Spark and Flink must read the same entity reference and use the same matching thresholds.

## Open Items

- Validate that the final SUMO network covers all selected OSM geometries, especially the airport and motorway corridors.
