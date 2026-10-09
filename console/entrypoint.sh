#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${ALLOWEDORIGINS:-}" ]]; then
  printf 'ERROR: ALLOWEDORIGINS must contain the browser-facing Console origin.\n' >&2
  exit 1
fi

install -d -o pk3s -g pk3s /home/pk3s/.pk3s /home/pk3s/.kube
chown pk3s:pk3s /home/pk3s/.pk3s /home/pk3s/.kube

exec /opt/console/node_modules/.bin/wetty \
  --host 0.0.0.0 \
  --port 3000 \
  --title "Productive K3S Console" \
  --command /usr/local/bin/session.sh \
  --allowed-origin "${ALLOWEDORIGINS}" \
  --log-level "${WETTY_LOG_LEVEL:-info}"
