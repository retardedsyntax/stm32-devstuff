#! /usr/bin/env bash

set -exuo pipefail

# Source common functions with funky bash, as per: https://stackoverflow.com/a/12694189
DIR="${BASH_SOURCE%/*}"
test -d "$DIR" || DIR=$PWD

# shellcheck source=utils/common.sh
. "$DIR/utils/common.sh"

#####################
# Common vars

cleanup() {
  apt_clean
  rm -rf "${PICOTOOL_BUILDDIR}"
}

trap cleanup EXIT

# Common vars
#####################

# Install misc needed packages
as_root apt-get update && apt-get -y upgrade
as_root apt-get install -y --no-install-recommends \
  clangd gdb-multiarch

