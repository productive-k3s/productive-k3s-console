#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${ALLOWEDORIGINS:-}" ]]; then
  printf 'ERROR: ALLOWEDORIGINS must contain the browser-facing Console origin.\n' >&2
  exit 1
fi

install -d -m 0700 -o pk3s -g pk3s /home/pk3s/.ssh
install -d -o pk3s -g pk3s /home/pk3s/.cache /home/pk3s/.pk3s /home/pk3s/.kube
if ! setpriv --reuid=pk3s --regid=pk3s --init-groups \
  test -r /home/pk3s/config -a -w /home/pk3s/config -a -x /home/pk3s/config; then
  printf 'ERROR: PK3S_CONFIG_DIR must be accessible to container UID/GID 10001:10001.\n' >&2
  printf 'Prepare the dedicated host directory before starting Console; ownership is never changed automatically.\n' >&2
  exit 1
fi
chown pk3s:pk3s /home/pk3s/.ssh
chown pk3s:pk3s /home/pk3s/.cache /home/pk3s/.pk3s /home/pk3s/.kube
setpriv --reuid=pk3s --regid=pk3s --init-groups mkdir -p \
  /home/pk3s/.cache/ansible/tmp \
  /home/pk3s/.cache/config \
  /home/pk3s/.cache/opentofu/plugins \
  /home/pk3s/.cache/state
setpriv --reuid=pk3s --regid=pk3s --init-groups chmod 0700 /home/pk3s/.ssh

exec /opt/console/node_modules/.bin/wetty \
  --host 0.0.0.0 \
  --port 3000 \
  --title "Productive K3S Console" \
  --command /usr/local/bin/session.sh \
  --allowed-origin "${ALLOWEDORIGINS}" \
  --log-level "${WETTY_LOG_LEVEL:-info}"
