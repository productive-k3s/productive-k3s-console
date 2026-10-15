#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACTS_DIR="${ROOT_DIR}/test-artifacts"
mkdir -p "${ARTIFACTS_DIR}"

docker compose --env-file "${ROOT_DIR}/.env.example" \
  -f "${ROOT_DIR}/docker-compose.yml" config --format json > "${ARTIFACTS_DIR}/compose.json"

bash "${ROOT_DIR}/scripts/run-in-venv.sh" python - "${ARTIFACTS_DIR}/compose.json" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
services = payload["services"]
console = services["console"]
auth = services["auth"]
assert not console.get("ports"), "console must not expose a host port"
assert auth.get("ports"), "auth must be the external entry point"
assert console["read_only"] is True
assert auth["read_only"] is True
assert "ALL" in console["cap_drop"] and "ALL" in auth["cap_drop"]
assert console["security_opt"] == ["no-new-privileges:true"]
assert auth["security_opt"] == ["no-new-privileges:true"]
assert set(payload["volumes"]) == {"cache-state", "kube-state", "pk3s-state", "ssh-state"}
assert any(mount["target"] == "/home/pk3s/.cache" for mount in console["volumes"])
assert any(mount["target"] == "/home/pk3s/.ssh" for mount in console["volumes"])
config_mounts = [mount for mount in console["volumes"] if mount["target"] == "/home/pk3s/config"]
assert len(config_mounts) == 1, "Console must expose exactly one Config bind mount"
assert config_mounts[0]["type"] == "bind"
assert config_mounts[0]["source"].endswith("/config")
assert set(console["cap_add"]) == {"CHOWN", "SETGID", "SETUID"}
assert payload["networks"]["console-internal"]["internal"] is True
assert auth["environment"]["OAUTH2_PROXY_UPSTREAMS"] == "http://console:3000"
assert console["environment"]["ALLOWEDORIGINS"] == "http://localhost:3000"
assert console["environment"]["PK3S_RUNTIME_DISABLED_SCENARIOS"] == "multipass"
PY

grep -Eq -- '--command /usr/local/bin/session.sh' "${ROOT_DIR}/console/entrypoint.sh"
grep -Eq '/home/pk3s/\.cache' "${ROOT_DIR}/console/entrypoint.sh"
grep -Eq '/home/pk3s/\.ssh' "${ROOT_DIR}/console/entrypoint.sh"
grep -Eq '^export ANSIBLE_HOME=/home/pk3s/\.cache/ansible$' "${ROOT_DIR}/console/session.sh"
grep -Eq '^export TF_PLUGIN_CACHE_DIR=/home/pk3s/\.cache/opentofu/plugins$' "${ROOT_DIR}/console/session.sh"
grep -Eq "'  1\. Productive K3S'" "${ROOT_DIR}/console/session.sh"
grep -Eq "'  2\. Config'" "${ROOT_DIR}/console/session.sh"
grep -Eq "'  3\. Exit'" "${ROOT_DIR}/console/session.sh"
grep -Eq '^run_pk3s\(\)' "${ROOT_DIR}/console/session.sh"
grep -Eq '^run_config\(\)' "${ROOT_DIR}/console/session.sh"
grep -Eq '^    pk3s ui$' "${ROOT_DIR}/console/session.sh"
grep -Eq '^    /usr/local/bin/config-workspace$' "${ROOT_DIR}/console/session.sh"
grep -Eq 'landlock_restrict_self' "${ROOT_DIR}/console/config-workspace.c"
grep -Eq 'PR_SET_NO_NEW_PRIVS' "${ROOT_DIR}/console/config-workspace.c"
grep -Eq -- '--verify-sandbox' "${ROOT_DIR}/console/config-workspace.c"
if grep -En '(system|popen|execv|execl|posix_spawn)[[:space:]]*\(' "${ROOT_DIR}/console/config-workspace.c"; then
  printf 'ERROR: Config workspace must not execute external commands.\n' >&2
  exit 1
fi
grep -Eq '^ARG PK3S_CLI_VERSION=0\.9\.69$' "${ROOT_DIR}/console/Dockerfile"
grep -Eq '^ARG PK3S_CONSOLE_VERSION=0\.1\.0-dev$' "${ROOT_DIR}/console/Dockerfile"
grep -Eq '^ARG PK3S_CLI_SHA256_AMD64=7b5cc23392dd0f17e343a507697ff879daf9aa5245c80ac0e6eea30633400dca$' "${ROOT_DIR}/console/Dockerfile"
grep -Eq '^ARG PK3S_CLI_SHA256_ARM64=31e1c5332da241c76247738f325d11e04b381d057ab2030cb19d46b0fd12aac2$' "${ROOT_DIR}/console/Dockerfile"
grep -Eq '^ARG OPENTOFU_VERSION=1\.12\.6$' "${ROOT_DIR}/console/Dockerfile"
grep -Eq '^ARG ANSIBLE_CORE_VERSION=2\.15\.13$' "${ROOT_DIR}/console/Dockerfile"
grep -Eq '^FROM wetty-builder AS config-workspace-builder$' "${ROOT_DIR}/console/Dockerfile"
grep -Eq 'cc -static -std=c11 -O2 -Wall -Wextra -Werror' "${ROOT_DIR}/console/Dockerfile"
grep -Eq 'productive-k3s-cli/releases/download/\$\{PK3S_CLI_VERSION\}/pk3s-\$\{PK3S_CLI_VERSION\}-linux-\$\{TARGETARCH\}\.tar\.gz' "${ROOT_DIR}/console/Dockerfile"
if grep -En '(cli-builder|PK3S_CLI_SOURCE_REVISION|git fetch|git clone)' "${ROOT_DIR}/console/Dockerfile"; then
  printf 'ERROR: Console must consume the released CLI archive, not build CLI from source.\n' >&2
  exit 1
fi
for material in ansible_core curl jq openssh-client python3 tofu; do
  grep -Eq "${material}" "${ROOT_DIR}/console/Dockerfile"
done
if grep -REn '(sshd|chpasswd|/var/run/docker.sock|docker.sock)' \
  "${ROOT_DIR}/console" "${ROOT_DIR}/docker-compose.yml"; then
  printf 'ERROR: forbidden SSH, password, or Docker socket surface found.\n' >&2
  exit 1
fi
grep -Eq -- '--build-arg "PK3S_CONSOLE_VERSION=\$\{VERSION\}"' "${ROOT_DIR}/scripts/build.sh"
grep -Eq 'make smoke IMAGE="\$\{IMAGE_VERSION\}" VERSION="\$\{CONSOLE_VERSION\}"' \
  "${ROOT_DIR}/.github/workflows/release.yml"
grep -Eq 'org\.opencontainers\.image\.version' "${ROOT_DIR}/scripts/smoke.sh"

test -f "${ROOT_DIR}/.gitmodules"
grep -Eq 'path = \.shared/productive-k3s-docs-theme' "${ROOT_DIR}/.gitmodules"
for target in docs-build docs-serve docs-up docs-down docs-clean; do
  grep -Eq "^${target}:" "${ROOT_DIR}/Makefile"
  grep -Eq "^${target}:" "${ROOT_DIR}/docs/Makefile"
done

disabled_up="$(make -C "${ROOT_DIR}" --no-print-directory -n up AUTH_MODE=disabled)"
[[ "${disabled_up}" == *'--env-file ".env.example"'* ]]
[[ "${disabled_up}" == *'-f docker-compose.dev.yml up -d --build console'* ]]
grep -Eq '# Open http://localhost:3000' "${ROOT_DIR}/README.md"
grep -Eq '^config/$' "${ROOT_DIR}/.gitignore"
grep -Eq '^PK3S_CONFIG_DIR=\./config$' "${ROOT_DIR}/.env.example"
disabled_down="$(make -C "${ROOT_DIR}" --no-print-directory -n down AUTH_MODE=disabled)"
[[ "${disabled_down}" == *'-f docker-compose.dev.yml down'* ]]
oidc_up="$(make -C "${ROOT_DIR}" --no-print-directory -n up)"
[[ "${oidc_up}" == *'--env-file ".env" -f docker-compose.yml up -d --build'* ]]
if make -C "${ROOT_DIR}" --no-print-directory -n up AUTH_MODE=invalid >/dev/null 2>&1; then
  printf 'ERROR: invalid AUTH_MODE was accepted.\n' >&2
  exit 1
fi

for relative_path in \
  main.html \
  partials/logo.html \
  partials/header.html \
  partials/footer.html \
  partials/toc.html; do
  cmp -s \
    "${ROOT_DIR}/.shared/productive-k3s-docs-theme/material-overrides/${relative_path}" \
    "${ROOT_DIR}/docs/src/overrides/${relative_path}"
done
for relative_path in \
  assets/stylesheets/extra.css \
  assets/images/argentina.png \
  assets/images/productive-k3s-icon-square-0.3x.png \
  assets/images/favicon.ico; do
  cmp -s \
    "${ROOT_DIR}/.shared/productive-k3s-docs-theme/material-overrides/${relative_path}" \
    "${ROOT_DIR}/docs/src/${relative_path}"
done

mapfile -t english_pages < <(find "${ROOT_DIR}/docs/src/en" -type f -name '*.md' -printf '%P\n' | sort)
mapfile -t spanish_pages < <(find "${ROOT_DIR}/docs/src/es" -type f -name '*.md' -printf '%P\n' | sort)
if [[ "${english_pages[*]}" != "${spanish_pages[*]}" ]]; then
  printf 'ERROR: English and Spanish documentation page maps differ.\n' >&2
  diff -u <(printf '%s\n' "${english_pages[@]}") <(printf '%s\n' "${spanish_pages[@]}") >&2 || true
  exit 1
fi

printf 'Console contracts passed.\n'
