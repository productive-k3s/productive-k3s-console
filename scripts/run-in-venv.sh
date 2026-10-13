#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="${ROOT_DIR}/.venv"
REQUIREMENTS="${ROOT_DIR}/requirements-dev.txt"
STAMP="${VENV_DIR}/.requirements-stamp"

python3 -m venv "${VENV_DIR}"
# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"
if [[ ! -f "${STAMP}" || "${REQUIREMENTS}" -nt "${STAMP}" ]]; then
  python -m pip install --disable-pip-version-check -q -r "${REQUIREMENTS}"
  touch "${STAMP}"
fi

exec "$@"
