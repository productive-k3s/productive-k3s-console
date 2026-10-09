#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mapfile -t shell_files < <(find "${ROOT_DIR}" -path "${ROOT_DIR}/.venv" -prune -o -type f -name '*.sh' -print)
shellcheck "${shell_files[@]}"
if rg -n '(^|[[:space:]/:@])latest([[:space:]@]|$)' \
  "${ROOT_DIR}/console/Dockerfile" "${ROOT_DIR}/docker-compose.yml" "${ROOT_DIR}/materials.lock.yaml"; then
  printf 'ERROR: floating latest reference found.\n' >&2
  exit 1
fi

bash "${ROOT_DIR}/scripts/validate.sh"
printf 'Static checks passed.\n'
