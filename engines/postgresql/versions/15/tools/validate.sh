#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../../../../.." && pwd)"
TARGET_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

exec "${ROOT_DIR}/scripts/validate-version.sh" "${TARGET_DIR}"
