#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IMAGE:-productive-k3s-console:dev}"
REVISION="$(git -C "${ROOT_DIR}" rev-parse HEAD)"

bash "${ROOT_DIR}/scripts/render-bom.sh" --source-revision "${REVISION}"
docker build \
  --label "org.opencontainers.image.revision=${REVISION}" \
  --tag "${IMAGE}" \
  --file "${ROOT_DIR}/console/Dockerfile" \
  "${ROOT_DIR}"
