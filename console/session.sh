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

run_pk3s() {
  setpriv \
    --reuid=pk3s \
    --regid=pk3s \
    --init-groups \
    --inh-caps=-all \
    --ambient-caps=-all \
    --bounding-set=-all \
    pk3s ui
}

run_config() {
  setpriv \
    --reuid=pk3s \
    --regid=pk3s \
    --init-groups \
    --inh-caps=-all \
    --ambient-caps=-all \
    --bounding-set=-all \
    /usr/local/bin/config-workspace
}

cd "${HOME}"
while true; do
  printf '\033[2J\033[H'
  printf '%s\n' \
    'Productive K3S Console' \
    '' \
    '  1. Productive K3S' \
    '  2. Config' \
    '  3. Exit' \
    ''
  if ! read -r -p 'Select [1-3]: ' selection; then
    exit 0
  fi
  case "${selection}" in
    1)
      run_pk3s || printf 'Productive K3S exited with an error.\n' >&2
      ;;
    2)
      run_config || printf 'Config workspace exited with an error.\n' >&2
      ;;
    3)
      exit 0
      ;;
    *)
      printf 'Invalid selection.\n' >&2
      sleep 1
      ;;
  esac
done
