# Event Schemas

## Purpose

This document defines the canonical Kafka contracts for the Toulouse mobility analytics pipeline. Spark Structured Streaming and Flink must consume the same input topics, use the same window arguments, read the same spatial reference, and emit equivalent result events.

Schemas are documented here before implementation. The first implementation should use UTF-8 JSON values and Kafka message keys as described below. A schema registry can be added later only if it removes real operational friction.

## Topic Summary

| Topic | Key | Value schema | Producer | Consumers |
| --- | --- | --- | --- | --- |
| `mobility.fcd` | `vehicle_id` | FCD vehicle event | file-to-Kafka producer | Spark traffic job, Flink traffic job |
| `mobility.emissions` | `vehicle_id` | emission vehicle event | file-to-Kafka producer | Spark pollution job, Flink pollution job |
| `analytics.traffic` | `engine/entity_id/window_start/window_end/window_kind` | traffic aggregate event | Spark traffic job, Flink traffic job | result consumer/map |
| `analytics.pollution` | `engine/entity_id/window_start/window_end/window_kind` | pollution aggregate event | Spark pollution job, Flink pollution job | result consumer/map |

Topic names are stable unless a later phase explicitly updates this document and both stream-processing implementations.

## Common Conventions

- Timestamp fields use ISO 8601 UTC strings with `Z`, for example `2026-07-02T20:00:00.000Z`.
- SUMO simulation time is preserved as `sim_time_s` in seconds from the scenario start.
- Coordinates use WGS84 longitude/latitude in decimal degrees when fields are named `lon` and `lat`.
- Projected SUMO coordinates, if kept, use meters and fields named `x_m` and `y_m`.
- Numeric pollutant fields keep SUMO units and are normalized to floating-point numbers.
- Missing source values are encoded as `null`, not empty strings.
- `schema_version` starts at `1` and increments only when a breaking schema change is introduced.
- Kafka headers are optional in the first implementation; all required routing data must be in the key or value.

## Spatial Reference Contract

All analytics jobs read `data/reference/toulouse_spatial_entities.geojson`.

Required feature properties:

| Property | Type | Notes |
| --- | --- | --- |
| `entity_id` | string | Stable grouping key in result events. |
| `name` | string | Human-readable display name. |
| `kind` | string | Entity category. |
| `osm_refs` | array of string | OSM objects used for the geometry. |
| `match_mode` | string | One of `radius`, `area_buffer`, `corridor`. |
| `radius_m` | number or absent | Required for `radius`. |
| `buffer_m` | number or absent | Required for `area_buffer` and `corridor`. |

Spark and Flink must implement the same matching interpretation:

- `radius`: point-to-point distance within `radius_m`.
- `area_buffer`: point inside polygon or within `buffer_m` of the polygon boundary.
- `corridor`: point within `buffer_m` of any line segment in the `MultiLineString`.

Distance calculations must use a metric projection or geodesic distance, not raw degree differences.

## Input Schema: `mobility.fcd`

Kafka key: `vehicle_id`.

Required value fields:

| Field | Type | Notes |
| --- | --- | --- |
| `schema_version` | integer | `1`. |
| `source` | string | `sumo_fcd`. |
| `run_id` | string | SUMO generation run identifier. |
| `event_ts` | string | Event timestamp derived from SUMO simulation time. |
| `ingest_ts` | string | Producer timestamp when the event is published. |
| `sim_time_s` | number | SUMO simulation time in seconds. |
| `vehicle_id` | string | SUMO vehicle identifier. |
| `vehicle_type` | string or null | SUMO vehicle type. |
| `lane_id` | string or null | SUMO lane identifier. |
| `x_m` | number or null | SUMO projected x coordinate. |
| `y_m` | number or null | SUMO projected y coordinate. |
| `lon` | number or null | WGS84 longitude after network projection conversion. |
| `lat` | number or null | WGS84 latitude after network projection conversion. |
| `speed_mps` | number | Vehicle speed in meters per second. |
| `angle_deg` | number or null | Vehicle angle from SUMO. |
| `position_m` | number or null | Position on lane, if available. |
| `slope_deg` | number or null | Road slope, if available. |

Minimum example:

```json
{
  "schema_version": 1,
  "source": "sumo_fcd",
  "run_id": "tls_sumo_001",
  "event_ts": "2026-07-02T20:00:12.000Z",
  "ingest_ts": "2026-07-02T20:05:00.100Z",
  "sim_time_s": 12.0,
  "vehicle_id": "veh_42",
  "vehicle_type": "passenger",
  "lane_id": "edge_1_0",
  "x_m": 574102.2,
  "y_m": 4829581.4,
  "lon": 1.44335,
  "lat": 43.60440,
  "speed_mps": 8.4,
  "angle_deg": 91.2,
  "position_m": 33.7,
  "slope_deg": 0.0
}
```

## Input Schema: `mobility.emissions`

Kafka key: `vehicle_id`.

Required value fields:

| Field | Type | Notes |
| --- | --- | --- |
| `schema_version` | integer | `1`. |
| `source` | string | `sumo_emissions`. |
| `run_id` | string | SUMO generation run identifier. |
| `event_ts` | string | Event timestamp derived from SUMO simulation time. |
| `ingest_ts` | string | Producer timestamp when the event is published. |
| `sim_time_s` | number | SUMO simulation time in seconds. |
| `vehicle_id` | string | SUMO vehicle identifier. |
| `vehicle_type` | string or null | SUMO vehicle type. |
| `emission_class` | string or null | SUMO emission class. |
| `lane_id` | string or null | SUMO lane identifier. |
| `x_m` | number or null | SUMO projected x coordinate. |
| `y_m` | number or null | SUMO projected y coordinate. |
| `lon` | number or null | WGS84 longitude after network projection conversion. |
| `lat` | number or null | WGS84 latitude after network projection conversion. |
| `speed_mps` | number or null | Vehicle speed in meters per second. |
| `co2_mg_s` | number or null | SUMO `CO2` value. |
| `co_mg_s` | number or null | SUMO `CO` value. |
| `hc_mg_s` | number or null | SUMO `HC` value. |
| `nox_mg_s` | number or null | SUMO `NOx` value. |
| `pmx_mg_s` | number or null | SUMO `PMx` value. |
| `fuel_mg_s` | number or null | SUMO `fuel` value. |
| `electricity_wh_s` | number or null | SUMO `electricity` value, if available. |
| `noise_db` | number or null | SUMO `noise` value, if available. |
| `waiting_s` | number or null | SUMO `waiting` value, if available. |

Minimum example:

```json
{
  "schema_version": 1,
  "source": "sumo_emissions",
  "run_id": "tls_sumo_001",
  "event_ts": "2026-07-02T20:00:12.000Z",
  "ingest_ts": "2026-07-02T20:05:00.100Z",
  "sim_time_s": 12.0,
  "vehicle_id": "veh_42",
  "vehicle_type": "passenger",
  "emission_class": "HBEFA3/PC_G_EU4",
  "lane_id": "edge_1_0",
  "x_m": 574102.2,
  "y_m": 4829581.4,
  "lon": 1.44335,
  "lat": 43.60440,
  "speed_mps": 8.4,
  "co2_mg_s": 1710.5,
  "co_mg_s": 21.4,
  "hc_mg_s": 0.9,
  "nox_mg_s": 2.1,
  "pmx_mg_s": 0.04,
  "fuel_mg_s": 735.2,
  "electricity_wh_s": null,
  "noise_db": 63.2,
  "waiting_s": 0.0
}
```

## Result Schema: `analytics.traffic`

Kafka key: `engine/entity_id/window_start/window_end/window_kind`.

Required value fields:

| Field | Type | Notes |
| --- | --- | --- |
| `schema_version` | integer | `1`. |
| `engine` | string | `spark` or `flink`. |
| `run_id` | string | SUMO generation run identifier. |
| `job_id` | string | Analytics job/run identifier. |
| `entity_id` | string | Spatial entity key. |
| `entity_name` | string | Display name copied from the reference. |
| `entity_kind` | string | Kind copied from the reference. |
| `window_kind` | string | `tumbling` or `sliding`. |
| `window_size_s` | integer | Window size in seconds. |
| `window_slide_s` | integer or null | Slide interval for sliding windows; `null` for tumbling windows. |
| `window_start` | string | Inclusive event-time window start. |
| `window_end` | string | Exclusive event-time window end. |
| `matched_vehicle_count` | integer | Number of matched FCD records or distinct vehicles, as configured. |
| `distinct_vehicle_count` | integer | Distinct vehicles observed in the window. |
| `avg_speed_mps` | number or null | Average speed across matched records. |
| `slow_vehicle_count` | integer | Count below the configured slow-speed threshold. |
| `stopped_vehicle_count` | integer | Count below the configured stopped-speed threshold. |
| `source_topic` | string | `mobility.fcd`. |
| `emitted_ts` | string | Analytics output timestamp. |

## Result Schema: `analytics.pollution`

Kafka key: `engine/entity_id/window_start/window_end/window_kind`.

Required value fields:

| Field | Type | Notes |
| --- | --- | --- |
| `schema_version` | integer | `1`. |
| `engine` | string | `spark` or `flink`. |
| `run_id` | string | SUMO generation run identifier. |
| `job_id` | string | Analytics job/run identifier. |
| `entity_id` | string | Spatial entity key. |
| `entity_name` | string | Display name copied from the reference. |
| `entity_kind` | string | Kind copied from the reference. |
| `window_kind` | string | `tumbling` or `sliding`. |
| `window_size_s` | integer | Window size in seconds. |
| `window_slide_s` | integer or null | Slide interval for sliding windows; `null` for tumbling windows. |
| `window_start` | string | Inclusive event-time window start. |
| `window_end` | string | Exclusive event-time window end. |
| `matched_vehicle_count` | integer | Number of matched emission records or distinct vehicles, as configured. |
| `distinct_vehicle_count` | integer | Distinct vehicles observed in the window. |
| `avg_co2_mg_s` | number or null | Average CO2 emission rate. |
| `avg_co_mg_s` | number or null | Average CO emission rate. |
| `avg_hc_mg_s` | number or null | Average HC emission rate. |
| `avg_nox_mg_s` | number or null | Average NOx emission rate. |
| `avg_pmx_mg_s` | number or null | Average PMx emission rate. |
| `sum_fuel_mg_s` | number or null | Sum of fuel values over matched records. |
| `source_topic` | string | `mobility.emissions`. |
| `emitted_ts` | string | Analytics output timestamp. |

## Runtime Window Arguments

Both Spark and Flink jobs must accept the same logical arguments:

| Argument | Values | Notes |
| --- | --- | --- |
| `--window-kind` | `tumbling`, `sliding` | Required. |
| `--window-size-s` | positive integer | Required. |
| `--window-slide-s` | positive integer | Required for sliding windows; omitted for tumbling windows. |
| `--watermark-delay-s` | non-negative integer | Same value for Spark and Flink benchmark runs. |
| `--slow-speed-threshold-mps` | non-negative number | Used by traffic analytics. |
| `--stopped-speed-threshold-mps` | non-negative number | Used by traffic analytics. |
| `--spatial-reference` | path | Defaults to `data/reference/toulouse_spatial_entities.geojson`. |

## Compatibility Rules

- Spark and Flink must use identical topic names, field names, window boundaries, and spatial matching thresholds.
- Result events must include the `engine` field so benchmark consumers can compare output streams.
- Any producer-side coordinate conversion must be shared by both raw topics.
- If a later phase changes a field name, unit, or topic name, update this document before code changes.
