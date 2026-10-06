#!/usr/bin/env bash
set -Eeuo pipefail

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  echo "Usage: PROFILE=1gb $0 engines/<engine>/versions/<version>" >&2
  exit 2
}

size_to_bytes() {
  local raw="$1"
  local value
  local unit

  raw="${raw//[[:space:]]/}"
  [[ "${raw}" =~ ^([0-9]+)([[:alpha:]]*)$ ]] || fail "Unsupported size value: ${1}"
  value="${BASH_REMATCH[1]}"
  unit="${BASH_REMATCH[2],,}"

  case "${unit}" in
    ""|b) echo "${value}" ;;
    k|kb|kib) echo "$((value * 1024))" ;;
    m|mb|mib) echo "$((value * 1024 * 1024))" ;;
    g|gb|gib) echo "$((value * 1024 * 1024 * 1024))" ;;
    *) fail "Unsupported size unit in: ${1}" ;;
  esac
}

read_assignment() {
  local file="$1"
  local wanted="$2"

  awk -F= -v wanted="${wanted}" '
    {
      key = $1
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
      if (key == wanted) {
        value = $2
        sub(/[[:space:]]*[#;].*$/, "", value)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        gsub(/^\047|\047$/, "", value)
        print value
        exit
      }
    }
  ' "${file}"
}

[[ "$#" -eq 1 ]] || usage

target="$1"
[[ -d "${target}/tools" ]] || fail "Invalid target: ${target}"
target="$(cd -- "${target}" && pwd)"
engine="$(basename -- "$(dirname -- "$(dirname -- "${target}")")")"
version="$(basename -- "${target}")"
profile="${PROFILE:-${DB_PROFILE:-1gb}}"

case "${engine}" in
  mysql) sql_client="mysql" ;;
  mariadb) sql_client="mariadb" ;;
  postgresql) sql_client="" ;;
  *) fail "Unsupported engine: ${engine}" ;;
esac

case "${profile}" in
  1gb|2gb|4gb|8gb) ;;
  *) fail "Unsupported PROFILE='${profile}'. Expected: 1gb, 2gb, 4gb, 8gb" ;;
esac

command -v docker >/dev/null 2>&1 || fail "docker not found"
docker compose version >/dev/null 2>&1 || fail "docker compose not found"

tools_dir="${target}/tools"
project_name="db-tuning-${engine}-${version//./-}-${profile}"
export DB_PROFILE="${profile}"
compose=(docker compose -p "${project_name}" -f "${tools_dir}/docker-compose.yml")

cleanup() {
  "${compose[@]}" down -v --remove-orphans >/dev/null 2>&1 || true
}
trap cleanup EXIT

printf 'Validating %s %s with profile %s\n' "${engine}" "${version}" "${profile}"
"${compose[@]}" config >/dev/null
"${compose[@]}" up -d

ready=0
for _ in $(seq 1 60); do
  case "${engine}" in
    mysql|mariadb)
      if "${compose[@]}" exec -T db "${sql_client}" -uroot -proot --batch --skip-column-names -e 'SELECT 1;' >/dev/null 2>&1; then
        ready=1
      fi
      ;;
    postgresql)
      if "${compose[@]}" exec -T db pg_isready -U postgres >/dev/null 2>&1; then
        ready=1
      fi
      ;;
  esac

  [[ "${ready}" -eq 1 ]] && break
  sleep 1
done

if [[ "${ready}" -ne 1 ]]; then
  echo "DB is not ready. Logs:" >&2
  "${compose[@]}" logs --no-color db | tail -200 >&2 || true
  fail "database readiness timeout"
fi

case "${engine}" in
  mysql|mariadb)
    profile_file="${target}/conf.d/profiles/${profile}.cnf"
    expected_pool="$(read_assignment "${profile_file}" innodb_buffer_pool_size)"
    [[ -n "${expected_pool}" ]] || fail "innodb_buffer_pool_size is missing in ${profile_file}"
    expected_pool_bytes="$(size_to_bytes "${expected_pool}")"

    actual_pool="$("${compose[@]}" exec -T db "${sql_client}" -uroot -proot --batch --skip-column-names -e 'SELECT @@innodb_buffer_pool_size;' | tr -d '\r' | tail -n1)"
    [[ "${actual_pool}" == "${expected_pool_bytes}" ]] || fail "profile not applied: innodb_buffer_pool_size=${actual_pool}, expected ${expected_pool_bytes}"

    slow_log="$("${compose[@]}" exec -T db "${sql_client}" -uroot -proot --batch --skip-column-names -e 'SELECT @@slow_query_log;' | tr -d '\r' | tail -n1)"
    [[ "${slow_log}" == "1" ]] || fail "slow_query_log is not enabled"

    "${compose[@]}" exec -T db "${sql_client}" -uroot -proot -e \
      'SELECT VERSION() AS version, @@innodb_buffer_pool_size AS buffer_pool_bytes, @@max_connections AS max_connections, @@slow_query_log AS slow_query_log, @@long_query_time AS long_query_time;'
    ;;
  postgresql)
    profile_file="${target}/conf/conf.d/profiles/${profile}.conf"
    expected_shared="$(read_assignment "${profile_file}" shared_buffers)"
    [[ -n "${expected_shared}" ]] || fail "shared_buffers is missing in ${profile_file}"
    expected_shared_bytes="$(size_to_bytes "${expected_shared}")"

    actual_shared="$("${compose[@]}" exec -T db psql -U postgres -Atqc 'SHOW shared_buffers' | tr -d '\r' | tail -n1)"
    actual_shared_bytes="$(size_to_bytes "${actual_shared}")"
    [[ "${actual_shared_bytes}" == "${expected_shared_bytes}" ]] || fail "profile not applied: shared_buffers=${actual_shared}, expected ${expected_shared}"

    slow_threshold="$("${compose[@]}" exec -T db psql -U postgres -Atqc 'SHOW log_min_duration_statement' | tr -d '\r' | tail -n1)"
    [[ "${slow_threshold}" != "-1" && "${slow_threshold}" != "off" ]] || fail "log_min_duration_statement is disabled"

    "${compose[@]}" exec -T db psql -U postgres \
      -c 'SELECT version();' \
      -c 'SHOW shared_buffers;' \
      -c 'SHOW effective_cache_size;' \
      -c 'SHOW work_mem;' \
      -c 'SHOW maintenance_work_mem;' \
      -c 'SHOW log_min_duration_statement;'
    ;;
esac

printf 'OK: %s %s profile %s is active and verified\n' "${engine}" "${version}" "${profile}"
