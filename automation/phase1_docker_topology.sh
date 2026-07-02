#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

EXPECTED_TOPICS=$'analytics.pollution\nanalytics.traffic\nmobility.emissions\nmobility.fcd'

log() {
  printf '\n[phase1] %s\n' "$*"
}

compose() {
  docker compose "$@"
}

cleanup() {
  compose --profile spark --profile flink down --remove-orphans >/dev/null 2>&1 || true
}

wait_for_service_state() {
  local service="$1"
  local expected_state="$2"
  local timeout_seconds="${3:-90}"
  local state=""

  for _ in $(seq 1 "$timeout_seconds"); do
    state="$(
      compose ps --all --format '{{.Service}} {{.State}}' |
        awk -v service="$service" '$1 == service { print $2; exit }'
    )"

    if [[ "$state" == "$expected_state" ]]; then
      return 0
    fi

    sleep 1
  done

  printf 'Service %s did not reach state %s; last state: %s\n' "$service" "$expected_state" "${state:-missing}" >&2
  compose ps --all >&2 || true
  return 1
}

assert_service_absent() {
  local service="$1"

  if compose ps --all --format '{{.Service}}' | grep -Fxq "$service"; then
    printf 'Service %s should not be present in this run mode.\n' "$service" >&2
    compose ps --all >&2 || true
    return 1
  fi
}

assert_topics() {
  local topics=""

  for _ in $(seq 1 90); do
    topics="$(
      compose exec -T kafka /opt/kafka/bin/kafka-topics.sh \
        --bootstrap-server kafka:19092 \
        --list 2>/dev/null |
        sort
    )"

    if [[ "$topics" == "$EXPECTED_TOPICS" ]]; then
      return 0
    fi

    sleep 1
  done

  printf 'Kafka topics did not match expected set.\n\nExpected:\n%s\n\nActual:\n%s\n' "$EXPECTED_TOPICS" "$topics" >&2
  return 1
}

assert_log_contains() {
  local service="$1"
  local pattern="$2"
  local timeout_seconds="${3:-90}"

  for _ in $(seq 1 "$timeout_seconds"); do
    if compose logs "$service" 2>/dev/null | grep -Fq "$pattern"; then
      return 0
    fi

    sleep 1
  done

  printf 'Logs for %s did not contain expected pattern: %s\n' "$service" "$pattern" >&2
  compose logs "$service" >&2 || true
  return 1
}

validate_static_config() {
  log "Validating Compose profile expansion"
  compose config >/dev/null
  compose --profile spark config >/dev/null
  compose --profile flink config >/dev/null
  compose --profile spark --profile flink config >/dev/null
}

run_full_mode_smoke() {
  log "Checking full mode"
  cleanup
  compose --profile spark --profile flink up -d

  wait_for_service_state kafka running
  wait_for_service_state kafka-init exited
  wait_for_service_state spark-master running
  wait_for_service_state spark-worker-1 running
  wait_for_service_state flink-master running
  wait_for_service_state flink-worker-1 running
  assert_topics
  assert_log_contains spark-worker-1 "Starting Spark worker" 30
  assert_log_contains spark-worker-1 "with 8 cores" 30
  assert_log_contains flink-worker-1 "taskmanager.numberOfTaskSlots: 8" 30
}

run_spark_only_smoke() {
  log "Checking spark-only mode"
  cleanup
  compose --profile spark up -d

  wait_for_service_state kafka running
  wait_for_service_state kafka-init exited
  wait_for_service_state spark-master running
  wait_for_service_state spark-worker-1 running
  assert_service_absent flink-master
  assert_service_absent flink-worker-1
  assert_topics
  assert_log_contains spark-worker-1 "Starting Spark worker" 30
  assert_log_contains spark-worker-1 "with 8 cores" 30
}

run_flink_only_smoke() {
  log "Checking flink-only mode"
  cleanup
  compose --profile flink up -d

  wait_for_service_state kafka running
  wait_for_service_state kafka-init exited
  wait_for_service_state flink-master running
  wait_for_service_state flink-worker-1 running
  assert_service_absent spark-master
  assert_service_absent spark-worker-1
  assert_topics
  assert_log_contains flink-worker-1 "taskmanager.numberOfTaskSlots: 8" 30
}

main() {
  trap cleanup EXIT

  log "Checking Docker Compose availability"
  docker compose version >/dev/null

  validate_static_config
  run_full_mode_smoke
  run_spark_only_smoke
  run_flink_only_smoke

  log "Phase 1 Docker topology checkpoint passed"
}

main "$@"
