#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="pk3s-console-smoke"
PORT="${PK3S_CONSOLE_SMOKE_PORT:-13000}"
IMAGE="${IMAGE:-productive-k3s-console:dev}"
COMPOSE=(docker compose --project-name "${PROJECT}" --env-file "${ROOT_DIR}/.env.example" -f "${ROOT_DIR}/docker-compose.yml" -f "${ROOT_DIR}/docker-compose.dev.yml")

cleanup() {
  "${COMPOSE[@]}" down --volumes --remove-orphans >/dev/null 2>&1 || true
}
trap cleanup EXIT

IMAGE="${IMAGE}" bash "${ROOT_DIR}/scripts/build.sh"
PK3S_CONSOLE_IMAGE="${IMAGE}" \
  PK3S_CONSOLE_PORT="${PORT}" \
  PK3S_CONSOLE_PUBLIC_ORIGIN="http://127.0.0.1:${PORT}" \
  "${COMPOSE[@]}" up -d --no-build console

for _ in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:${PORT}/" >/dev/null; then
    break
  fi
  sleep 2
done
curl -fsS "http://127.0.0.1:${PORT}/" >/dev/null

for tool in pk3s kubectl helm k9s; do
  PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console test -x "/usr/local/bin/${tool}"
done
assert_version() {
  local tool="$1"
  local expected="$2"
  shift 2
  local output
  output="$(PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console "$@" 2>&1)"
  if [[ "${output}" != *"${expected}"* ]]; then
    printf 'ERROR: %s did not report locked version %s. Output: %s\n' "${tool}" "${expected}" "${output}" >&2
    return 1
  fi
}
assert_version pk3s 0.9.65 pk3s version
assert_version kubectl v1.35.5 kubectl version --client
assert_version helm v3.21.0 helm version --short
assert_version k9s v0.51.0 k9s version --short
# The command substitution must run inside the container's shell.
# shellcheck disable=SC2016
PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console \
  setpriv --reuid=pk3s --regid=pk3s --init-groups sh -c 'test "$(id -u)" = "10001"'

PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console \
  setpriv --reuid=pk3s --regid=pk3s --init-groups sh -c \
  'printf "state survives recreation\n" > /home/pk3s/.pk3s/smoke-state'
PK3S_CONSOLE_IMAGE="${IMAGE}" \
  PK3S_CONSOLE_PORT="${PORT}" \
  PK3S_CONSOLE_PUBLIC_ORIGIN="http://127.0.0.1:${PORT}" \
  "${COMPOSE[@]}" up -d --force-recreate --no-build console
PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console \
  grep -q 'state survives recreation' /home/pk3s/.pk3s/smoke-state

printf 'Console smoke test passed.\n'
