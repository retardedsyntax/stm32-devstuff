#! /usr/bin/env bash
#
# Copyright 2020, Data61/CSIRO
#
# SPDX-License-Identifier: BSD-2-Clause
#

set -exuo pipefail

#####################
# Common vars

# Apt is being run in a script
: "${DEBIAN_FRONTEND:=noninteractive}"
export DEBIAN_FRONTEND

# Common vars
#####################

function command_exists() {
  command -v "$@" >/dev/null 2>&1
}

# Determine a working command to run things as root
ROOT_CMD=""
if command_exists sudo; then
  ROOT_CMD='sudo -E bash -c'
elif command_exists su; then
  ROOT_CMD='su -c'
else
  cat >&2 <<-'EOF'
    Error: this installer needs the ability to run commands as root.
    We are unable to find either "sudo" or "su" available to make this happen.
EOF
  exit 1
fi

function as_root() {
  # A function inspired from get.docker.com and https://stackoverflow.com/a/32280085
  # Designed to pick the best way to run a command as root

  set +x # We don't need to see all this every time
  local shell_cmd
  local cmd
  local user
  cmd=("$@")
  shell_cmd='bash -c'
  user="$(id -un 2>/dev/null || true)"

  if [[ "$user" != 'root' ]]; then
    shell_cmd="$ROOT_CMD"
  fi
  printf -v cmd_str "%q " "${cmd[@]}"
  set -x
  $shell_cmd "$cmd_str"
}

function try_nonroot_first() {
  # Attempts to run a command as is, but if it fails, it tries again using
  # 'as_root`. If it does have to do something as_root, it returns 1, so
  # any other things that need doing (such as chowning) can be done.
  # returning 1 for a "successful" command is a bit weird tho...
  set +x
  local cmd
  cmd=("$@")
  printf -v cmd_str '%s ' "${cmd[@]}"
  bash -c "$cmd_str" || {
    as_root "$@"
    set -x
    return 1
  }
  set -x
  return 0
}

function chown_dir_to_user() {
  set +x
  as_root chown -R "$(id -u)":"$(id -g)" "$1"
  set -x
}

function apt_clean() {
  as_root apt-get clean autoclean && apt-get autoremove --purge --yes && rm -rf /var/lib/apt/lists/*
}
