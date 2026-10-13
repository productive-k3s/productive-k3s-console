#!/usr/bin/env bash
set -euo pipefail

export HOME=/home/pk3s
export USER=pk3s
export LOGNAME=pk3s
export SHELL=/usr/sbin/nologin
export PATH=/opt/ansible/bin:/usr/local/bin:/usr/bin:/bin
export ANSIBLE_HOME=/home/pk3s/.cache/ansible
export ANSIBLE_LOCAL_TEMP=/home/pk3s/.cache/ansible/tmp
export TF_PLUGIN_CACHE_DIR=/home/pk3s/.cache/opentofu/plugins
export XDG_CONFIG_HOME=/home/pk3s/.cache/config
export XDG_STATE_HOME=/home/pk3s/.cache/state

cd "${HOME}"
exec setpriv \
  --reuid=pk3s \
  --regid=pk3s \
  --init-groups \
  --inh-caps=-all \
  --ambient-caps=-all \
  --bounding-set=-all \
  pk3s ui
