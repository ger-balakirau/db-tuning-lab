#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found" >&2
  exit 1
fi

docker compose up -d
trap 'docker compose down -v >/dev/null 2>&1 || true' EXIT

for _ in $(seq 1 60); do
  if docker compose exec -T db mysqladmin ping -uroot -proot --silent >/dev/null 2>&1; then
    docker compose exec -T db mysql -uroot -proot -e "SELECT VERSION();"
    echo "OK"
    exit 0
  fi
  sleep 1
done

echo "DB is not ready. Logs:" >&2
docker compose logs --no-color db | tail -200 >&2
exit 1
