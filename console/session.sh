#!/usr/bin/env bash
set -euo pipefail

export HOME=/home/pk3s
export USER=pk3s
export LOGNAME=pk3s
export SHELL=/usr/sbin/nologin
export PATH=/usr/local/bin:/usr/bin:/bin

cd "${HOME}"
exec setpriv \
  --reuid=pk3s \
  --regid=pk3s \
  --init-groups \
  --inh-caps=-all \
  --ambient-caps=-all \
  --bounding-set=-all \
  pk3s ui
