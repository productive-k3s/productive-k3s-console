#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for directory in "${ROOT_DIR}/test-artifacts" "${ROOT_DIR}/coverage"; do
  if [[ -d "${directory}" ]]; then
    find "${directory}" -mindepth 1 -delete
  fi
done

if [[ "${1:-}" != "--logs-only" && -d "${ROOT_DIR}/dist" ]]; then
  find "${ROOT_DIR}/dist" -mindepth 1 -delete
fi
