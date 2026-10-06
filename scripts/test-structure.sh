#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

assert_file() {
  local path="$1"
  [[ -f "${path}" ]] || fail "Missing file: ${path}"
}

assert_dir() {
  local path="$1"
  [[ -d "${path}" ]] || fail "Missing directory: ${path}"
}

assert_executable() {
  local path="$1"
  [[ -x "${path}" ]] || fail "File is not executable: ${path}"
}

assert_contains() {
  local path="$1"
  local pattern="$2"
  grep -Eq "${pattern}" "${path}" || fail "Expected pattern '${pattern}' in ${path}"
}

assert_not_contains() {
  local path="$1"
  local pattern="$2"
  ! grep -Eq "${pattern}" "${path}" || fail "Unexpected pattern '${pattern}' in ${path}"
}

assert_mysql_like_version() {
  local engine="$1"
  local version="$2"
  local base="engines/${engine}/versions/${version}"
  local compose="${base}/tools/docker-compose.yml"
  local validate="${base}/tools/validate.sh"
  local profile
  local profile_file

  assert_file "${base}/README.md"
  assert_file "${base}/conf.d/00-base.cnf"
  assert_file "${base}/conf.d/10-observability.cnf"
  assert_file "${compose}"
  assert_file "${validate}"
  assert_executable "${validate}"

  for profile in 1gb 2gb 4gb 8gb; do
    profile_file="${base}/conf.d/profiles/${profile}.cnf"
    assert_file "${profile_file}"
    assert_contains "${profile_file}" '^\[mysqld\]$'
    assert_contains "${profile_file}" '^innodb_buffer_pool_size='
    assert_contains "${profile_file}" '^innodb_log_buffer_size='
    assert_contains "${profile_file}" '^tmp_table_size='
    assert_contains "${profile_file}" '^max_heap_table_size='
    assert_contains "${profile_file}" '^thread_cache_size='
    assert_contains "${profile_file}" '^table_open_cache='
  done

  assert_contains "${base}/conf.d/00-base.cnf" '^\[mysqld\]$'
  assert_contains "${base}/conf.d/00-base.cnf" '^max_connections='
  assert_contains "${base}/conf.d/10-observability.cnf" '^\[mysqld\]$'
  assert_contains "${base}/conf.d/10-observability.cnf" '^slow_query_log=1$'
  assert_not_contains "${base}/conf.d/00-base.cnf" 'заготовка'
  assert_not_contains "${base}/conf.d/10-observability.cnf" 'заготовка'
  assert_contains "${compose}" "image:[[:space:]]+${engine}:${version}"
  assert_contains "${compose}" 'MYSQL_ROOT_PASSWORD:'
  assert_contains "${compose}" 'DB_PROFILE:-1gb'
  assert_contains "${compose}" 'db-data:/var/lib/mysql'
  assert_contains "${validate}" 'validate-version\.sh'
}

assert_postgresql_version() {
  local version="$1"
  local base="engines/postgresql/versions/${version}"
  local compose="${base}/tools/docker-compose.yml"
  local validate="${base}/tools/validate.sh"
  local profile
  local profile_file

  assert_file "${base}/README.md"
  assert_file "${base}/conf/postgresql.conf"
  assert_file "${base}/conf/conf.d/00-base.conf"
  assert_file "${base}/conf/conf.d/10-observability.conf"
  assert_file "${compose}"
  assert_file "${validate}"
  assert_executable "${validate}"

  for profile in 1gb 2gb 4gb 8gb; do
    profile_file="${base}/conf/conf.d/profiles/${profile}.conf"
    assert_file "${profile_file}"
    assert_contains "${profile_file}" '^[[:space:]]*shared_buffers[[:space:]]*='
    assert_contains "${profile_file}" '^[[:space:]]*effective_cache_size[[:space:]]*='
    assert_contains "${profile_file}" '^[[:space:]]*work_mem[[:space:]]*='
    assert_contains "${profile_file}" '^[[:space:]]*maintenance_work_mem[[:space:]]*='
  done

  assert_contains "${base}/conf/postgresql.conf" "include_dir[[:space:]]*=[[:space:]]*'/etc/postgresql/conf.d'"
  assert_contains "${base}/conf/conf.d/00-base.conf" '^[[:space:]]*max_connections[[:space:]]*='
  assert_contains "${base}/conf/conf.d/10-observability.conf" '^[[:space:]]*log_min_duration_statement[[:space:]]*=[[:space:]]*1000'
  assert_not_contains "${base}/conf/conf.d/00-base.conf" 'заготовка'
  assert_not_contains "${base}/conf/conf.d/10-observability.conf" 'заготовка'
  assert_contains "${compose}" "image:[[:space:]]+postgres:${version}"
  assert_contains "${compose}" 'POSTGRES_PASSWORD:'
  assert_contains "${compose}" 'DB_PROFILE:-1gb'
  assert_contains "${compose}" 'db-data:/var/lib/postgresql/data'
  assert_contains "${validate}" 'validate-version\.sh'
}

check_compose_configs() {
  local compose_file

  if ! docker compose version >/dev/null 2>&1; then
    printf 'docker compose not found; skipping compose config checks\n'
    return 0
  fi

  while IFS= read -r compose_file; do
    DB_PROFILE=1gb docker compose -f "${compose_file}" config >/dev/null
  done < <(find engines -path '*/tools/docker-compose.yml' | sort)
}

main() {
  local version
  local version_count

  assert_file "README.md"
  assert_file "shared/formulas.md"
  assert_file "shared/glossary.md"
  assert_file ".github/workflows/validate.yml"
  assert_file "scripts/validate-version.sh"
  assert_executable "scripts/validate-version.sh"

  for version in 5.5 5.6 5.7 8.0 8.4; do
    assert_mysql_like_version mysql "${version}"
  done

  for version in 5.5 10.0 10.1 10.2 10.3 10.4 10.5 10.6 10.11 11.4; do
    assert_mysql_like_version mariadb "${version}"
  done

  for version in 9.0 9.1 9.2 9.3 9.4 9.5 9.6 10 11 12 13 14 15 16 17; do
    assert_postgresql_version "${version}"
  done

  version_count="$(find engines -mindepth 3 -maxdepth 3 -type d -path '*/versions/*' | wc -l)"
  [[ "${version_count}" -eq 30 ]] || fail "Expected 30 version directories, got ${version_count}"

  check_compose_configs
  printf 'OK: structure validated across %s version directories\n' "${version_count}"
}

main "$@"
