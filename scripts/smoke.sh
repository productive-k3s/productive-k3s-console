#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="pk3s-console-smoke"
PORT="${PK3S_CONSOLE_SMOKE_PORT:-13000}"
IMAGE="${IMAGE:-productive-k3s-console:dev}"
VERSION="${VERSION:-0.1.0-dev}"
CONFIG_DIR="${ROOT_DIR}/test-artifacts/config-smoke"
mkdir -p "${CONFIG_DIR}"
chmod 0777 "${CONFIG_DIR}"
export PK3S_CONFIG_DIR="${CONFIG_DIR}"
COMPOSE=(docker compose --project-name "${PROJECT}" --env-file "${ROOT_DIR}/.env.example" -f "${ROOT_DIR}/docker-compose.yml" -f "${ROOT_DIR}/docker-compose.dev.yml")

cleanup() {
  "${COMPOSE[@]}" down --volumes --remove-orphans >/dev/null 2>&1 || true
}
trap cleanup EXIT

IMAGE="${IMAGE}" VERSION="${VERSION}" bash "${ROOT_DIR}/scripts/build.sh"
[[ "$(docker image inspect --format '{{ index .Config.Labels "org.opencontainers.image.version" }}' "${IMAGE}")" == "${VERSION}" ]]
[[ "$(docker image inspect --format '{{ index .Config.Labels "org.opencontainers.image.revision" }}' "${IMAGE}")" == "$(git -C "${ROOT_DIR}" rev-parse HEAD)" ]]
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

for tool in pk3s kubectl helm k9s tofu ansible-playbook curl jq python3 scp sha256sum ssh tar; do
  PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console sh -c "command -v ${tool} >/dev/null"
done
assert_version() {
  local tool="$1"
  local expected="$2"
  shift 2
  local output
  output="$(PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console \
    setpriv --reuid=pk3s --regid=pk3s --init-groups "$@" 2>&1)"
  if [[ "${output}" != *"${expected}"* ]]; then
    printf 'ERROR: %s did not report locked version %s. Output: %s\n' "${tool}" "${expected}" "${output}" >&2
    return 1
  fi
}
assert_version pk3s 0.9.69 pk3s version
assert_version kubectl v1.35.5 kubectl version --client
assert_version helm v3.21.0 helm version --short
assert_version k9s v0.51.0 k9s version --short
assert_version tofu 1.12.6 tofu version
assert_version ansible-core 2.15.13 ansible-playbook --version
assert_version jq jq-1.6 jq --version
# The command substitution must run inside the container's shell.
# shellcheck disable=SC2016
PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console \
  setpriv --reuid=pk3s --regid=pk3s --init-groups sh -c 'test "$(id -u)" = "10001"'

selector_output="$(printf '3\n' | PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console /usr/local/bin/session.sh)"
for selector_entry in '1. Productive K3S' '2. Config' '3. Exit'; do
  [[ "${selector_output}" == *"${selector_entry}"* ]]
done

PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console \
  setpriv --reuid=pk3s --regid=pk3s --init-groups \
  --inh-caps=-all --ambient-caps=-all --bounding-set=-all \
  /usr/local/bin/config-workspace --verify-sandbox

config_output="$(printf '%s\n' \
  'mkdir scratchdir' \
  'rmdir scratchdir' \
  'edit smoke.env' \
  'AWS_REGION=us-test-1' \
  '.save' \
  'view smoke.env' \
  'touch disposable' \
  'rm disposable' \
  'view ../.ssh/smoke-state' \
  'view /etc/passwd' \
  'sh' \
  'exit' | PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console \
    setpriv --reuid=pk3s --regid=pk3s --init-groups \
    --inh-caps=-all --ambient-caps=-all --bounding-set=-all \
    /usr/local/bin/config-workspace 2>&1)"
[[ "${config_output}" == *'Productive K3S Config workspace (uid=10001)'* ]]
[[ "${config_output}" == *'AWS_REGION=us-test-1'* ]]
[[ "${config_output}" == *'Parent traversal is not allowed.'* ]]
[[ "${config_output}" == *'Absolute paths are not allowed.'* ]]
[[ "${config_output}" == *'Unknown command: sh'* ]]
PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console \
  test "$(PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console \
    stat -c '%u:%g:%a' /home/pk3s/config/smoke.env)" = '10001:10001:600'
PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console \
  test ! -e /home/pk3s/config/disposable

PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console \
  setpriv --reuid=pk3s --regid=pk3s --init-groups sh -c \
  'printf "state survives recreation\n" > /home/pk3s/.pk3s/smoke-state'
PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console \
  setpriv --reuid=pk3s --regid=pk3s --init-groups sh -c \
  'mkdir -p /home/pk3s/.cache/pk3s && printf "cache survives recreation\n" > /home/pk3s/.cache/pk3s/smoke-state'
PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console \
  setpriv --reuid=pk3s --regid=pk3s --init-groups sh -c \
  'printf "ssh state survives recreation\n" > /home/pk3s/.ssh/smoke-state'
PK3S_CONSOLE_IMAGE="${IMAGE}" \
  PK3S_CONSOLE_PORT="${PORT}" \
  PK3S_CONSOLE_PUBLIC_ORIGIN="http://127.0.0.1:${PORT}" \
  "${COMPOSE[@]}" up -d --force-recreate --no-build console
PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console \
  grep -q 'state survives recreation' /home/pk3s/.pk3s/smoke-state
PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console \
  grep -q 'cache survives recreation' /home/pk3s/.cache/pk3s/smoke-state
PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console \
  setpriv --reuid=pk3s --regid=pk3s --init-groups \
  grep -q 'ssh state survives recreation' /home/pk3s/.ssh/smoke-state
PK3S_CONSOLE_IMAGE="${IMAGE}" "${COMPOSE[@]}" exec -T console \
  setpriv --reuid=pk3s --regid=pk3s --init-groups \
  grep -q 'AWS_REGION=us-test-1' /home/pk3s/config/smoke.env

printf 'Console smoke test passed.\n'
