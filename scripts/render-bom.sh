#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec bash "${ROOT_DIR}/scripts/run-in-venv.sh" python "${ROOT_DIR}/scripts/materials.py" render \
  --lock "${ROOT_DIR}/materials.lock.yaml" \
  --output "${ROOT_DIR}/dist/bom.json" \
  "$@"
