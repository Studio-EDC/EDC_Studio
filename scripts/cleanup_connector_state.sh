#!/usr/bin/env bash
set -euo pipefail

POSTGRES_CONTAINER="${POSTGRES_CONTAINER:-edc_postgres}"
MODE="dry-run"
STOP_CONTAINERS="true"
BACKUP_DIR=""
declare -a REQUESTED_DBS=()

usage() {
  cat <<'EOF'
Usage:
  ./scripts/cleanup_connector_state.sh [options]

Options:
  --execute                    Run the cleanup. Without this flag the script only previews.
  --db <database_name>         Limit the cleanup to one database. Can be used multiple times.
  --backup-dir <path>          Store pg_dump backups before cleanup.
  --postgres-container <name>  Override the Postgres container name. Default: edc_postgres
  --no-stop                    Do not stop or restart connector containers.
  --help                       Show this help.

Examples:
  ./scripts/cleanup_connector_state.sh
  ./scripts/cleanup_connector_state.sh --execute
  ./scripts/cleanup_connector_state.sh --execute --db edc_provider_69f9db03be7843f8128bf887
  ./scripts/cleanup_connector_state.sh --execute --backup-dir ~/edc-db-backups
EOF
}

log() {
  printf '[cleanup] %s\n' "$*"
}

run_psql() {
  local db="$1"
  local sql="$2"
  docker exec -i "$POSTGRES_CONTAINER" psql -U postgres -d "$db" -At -F '|' -c "$sql"
}

list_target_dbs() {
  docker exec -i "$POSTGRES_CONTAINER" psql -U postgres -d postgres -At -c \
    "SELECT datname FROM pg_database WHERE datname LIKE 'edc\_%\_%' ESCAPE '\' ORDER BY datname"
}

connector_container_for_db() {
  local db="$1"
  case "$db" in
    edc_provider_*)
      printf 'edc-provider-%s\n' "${db#edc_provider_}"
      ;;
    edc_consumer_*)
      printf 'edc-consumer-%s\n' "${db#edc_consumer_}"
      ;;
    *)
      return 1
      ;;
  esac
}

container_exists() {
  local container="$1"
  docker ps -a --format '{{.Names}}' | grep -Fxq "$container"
}

container_is_running() {
  local container="$1"
  docker ps --format '{{.Names}}' | grep -Fxq "$container"
}

print_counts() {
  local db="$1"
  log "State for $db"
  run_psql "$db" "
    SELECT 'assets', count(*) FROM edc_asset
    UNION ALL
    SELECT 'contract_agreements', count(*) FROM edc_contract_agreement
    UNION ALL
    SELECT 'contract_definitions', count(*) FROM edc_contract_definitions
    UNION ALL
    SELECT 'contract_negotiations', count(*) FROM edc_contract_negotiation
    UNION ALL
    SELECT 'policies', count(*) FROM edc_policydefinitions
    UNION ALL
    SELECT 'transfer_processes', count(*) FROM edc_transfer_process
    ORDER BY 1;
  " | while IFS='|' read -r label count; do
    printf '  %-22s %s\n' "$label" "$count"
  done
}

backup_db() {
  local db="$1"
  local target_dir="$2"
  local target_file="$target_dir/$db.sql"

  mkdir -p "$target_dir"
  log "Creating backup $target_file"
  docker exec -i "$POSTGRES_CONTAINER" pg_dump -U postgres "$db" > "$target_file"
}

cleanup_db() {
  local db="$1"
  docker exec -i "$POSTGRES_CONTAINER" psql -U postgres -d "$db" <<'SQL'
TRUNCATE TABLE
  edc_transfer_process,
  edc_contract_negotiation,
  edc_contract_agreement,
  edc_contract_definitions,
  edc_policydefinitions,
  edc_asset,
  edc_lease
CASCADE;
SQL
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --execute)
      MODE="execute"
      shift
      ;;
    --db)
      [[ $# -ge 2 ]] || { echo "Missing value for --db" >&2; exit 1; }
      REQUESTED_DBS+=("$2")
      shift 2
      ;;
    --backup-dir)
      [[ $# -ge 2 ]] || { echo "Missing value for --backup-dir" >&2; exit 1; }
      BACKUP_DIR="$2"
      shift 2
      ;;
    --postgres-container)
      [[ $# -ge 2 ]] || { echo "Missing value for --postgres-container" >&2; exit 1; }
      POSTGRES_CONTAINER="$2"
      shift 2
      ;;
    --no-stop)
      STOP_CONTAINERS="false"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if ! container_exists "$POSTGRES_CONTAINER"; then
  echo "Postgres container '$POSTGRES_CONTAINER' was not found." >&2
  exit 1
fi

mapfile -t DISCOVERED_DBS < <(list_target_dbs)

if [[ ${#DISCOVERED_DBS[@]} -eq 0 ]]; then
  log "No connector databases found."
  exit 0
fi

declare -a TARGET_DBS=()
if [[ ${#REQUESTED_DBS[@]} -gt 0 ]]; then
  for requested in "${REQUESTED_DBS[@]}"; do
    found="false"
    for discovered in "${DISCOVERED_DBS[@]}"; do
      if [[ "$requested" == "$discovered" ]]; then
        TARGET_DBS+=("$requested")
        found="true"
        break
      fi
    done
    if [[ "$found" != "true" ]]; then
      echo "Database '$requested' was not found." >&2
      exit 1
    fi
  done
else
  TARGET_DBS=("${DISCOVERED_DBS[@]}")
fi

log "Target databases:"
printf '  %s\n' "${TARGET_DBS[@]}"

for db in "${TARGET_DBS[@]}"; do
  print_counts "$db"
done

if [[ "$MODE" != "execute" ]]; then
  log "Dry run only. Re-run with --execute to clean these databases."
  exit 0
fi

declare -A WAS_RUNNING=()

for db in "${TARGET_DBS[@]}"; do
  if [[ -n "$BACKUP_DIR" ]]; then
    backup_db "$db" "$BACKUP_DIR"
  fi

  if container_name="$(connector_container_for_db "$db" 2>/dev/null)"; then
    if [[ "$STOP_CONTAINERS" == "true" ]] && container_exists "$container_name"; then
      if container_is_running "$container_name"; then
        log "Stopping $container_name"
        docker stop "$container_name" >/dev/null
        WAS_RUNNING["$container_name"]="true"
      else
        WAS_RUNNING["$container_name"]="false"
      fi
    fi
  fi

  log "Cleaning $db"
  cleanup_db "$db"
done

if [[ "$STOP_CONTAINERS" == "true" ]]; then
  for db in "${TARGET_DBS[@]}"; do
    if container_name="$(connector_container_for_db "$db" 2>/dev/null)"; then
      if [[ "${WAS_RUNNING[$container_name]:-false}" == "true" ]]; then
        log "Starting $container_name"
        docker start "$container_name" >/dev/null
      fi
    fi
  done
fi

for db in "${TARGET_DBS[@]}"; do
  print_counts "$db"
done

log "Cleanup completed."
