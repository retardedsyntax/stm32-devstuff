#! /usr/bin/env bash
#
# Copyright 2020, Data61/CSIRO
#
# SPDX-License-Identifier: BSD-2-Clause
#

set -exuo pipefail

# Source common functions with funky bash, as per: https://stackoverflow.com/a/12694189
DIR="${BASH_SOURCE%/*}"
test -d "$DIR" || DIR=$PWD

# shellcheck source=utils/common.sh
. "$DIR/utils/common.sh"

cleanup() {
  apt_clean
}

trap cleanup EXIT

as_root apt-get update && apt-get -y upgrade
as_root apt-get install -y --no-install-recommends \
  iproute2 iputils-ping net-tools hostname traceroute \
  curl wget ca-certificates \
  bzip2 unzip xz-utils tar \
  git git-lfs gnupg2 \
  nano jq \
  pv sudo openssh-client \
  shellcheck shfmt clang-format clang-tidy \
  build-essential bc gawk bison flex texinfo yacc \
  python3 python3-dev python3-venv python3-pip python-is-python3 pipx

################################################################################

# Create venv for python packages to avoid externally managed error
PYVER="$(python3 -c 'from sys import version_info as ver; print("{}.{}".format(ver[0],ver[1]))')"
as_root python3 -m venv /opt/venv

{
cat <<EOF
export PATH=/opt/venv/bin\${PATH:+:\$PATH}
export PYTHONPATH=/opt/venv/lib/python${PYVER}/site-packages\${PYTHONPATH:+:\$PYTHONPATH}
EOF
} | as_root tee -a /etc/bash.bashrc

# Install some basic python tools
export PATH="/opt/venv/bin${PATH:+:$PATH}"
as_root pip3 install --no-cache-dir \
  setuptools \
  pyelftools \
  python-magic \
  cpplint \
  gitlint \
  nose \
  reuse \
  gdbgui

