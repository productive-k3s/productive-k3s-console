#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "${ROOT_DIR}/scripts/run-in-venv.sh" python "${ROOT_DIR}/scripts/materials.py" validate \
  --lock "${ROOT_DIR}/materials.lock.yaml"
docker compose --env-file "${ROOT_DIR}/.env.example" \
  -f "${ROOT_DIR}/docker-compose.yml" config --quiet
npm --prefix "${ROOT_DIR}" install --package-lock-only --ignore-scripts --no-audit --no-fund >/dev/null

printf 'Console validation passed.\n'
