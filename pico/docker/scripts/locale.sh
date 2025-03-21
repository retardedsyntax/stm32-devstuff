#! /usr/bin/env bash

set -exuo pipefail

# Source common functions with funky bash, as per: https://stackoverflow.com/a/12694189
DIR="${BASH_SOURCE%/*}"
test -d "$DIR" || DIR=$PWD

cleanup() {
  apt_clean
}

trap cleanup EXIT

# shellcheck source=utils/common.sh
. "$DIR/utils/common.sh"

as_root apt-get update && apt-get -y upgrade
as_root apt-get install -y --no-install-recommends tzdata locales
as_root sed -i -e 's/# C.UTF-8 UTF-8/C.UTF-8 UTF-8/' /etc/locale.gen
as_root sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
as_root dpkg-reconfigure --frontend=noninteractive locales
as_root ln -fs /usr/share/zoneinfo/Europe/Helsinki /etc/localtime \
  && dpkg-reconfigure --frontend=noninteractive tzdata

{
cat <<EOF
LANG=en_US.UTF-8
LANGUAGE=en_US:en
LC_ALL=C.UTF-8
EOF
} | as_root tee -a /etc/default/locale

