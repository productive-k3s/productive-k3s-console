#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "${ROOT_DIR}/coverage"
cd "${ROOT_DIR}"
bash scripts/run-in-venv.sh coverage run \
  --data-file coverage/.coverage \
  --source scripts.materials \
  -m unittest discover -s tests -p 'test_*.py'
bash scripts/run-in-venv.sh coverage report \
  --data-file coverage/.coverage \
  --fail-under=80 \
  --show-missing
