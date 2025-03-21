#! /usr/bin/env bash

set -exuo pipefail

# Source common functions with funky bash, as per: https://stackoverflow.com/a/12694189
DIR="${BASH_SOURCE%/*}"
test -d "$DIR" || DIR=$PWD

# shellcheck source=utils/common.sh
. "$DIR/utils/common.sh"

#####################
# Common vars

GCC_RELEASE="${GCC_RELEASE:-"releases/gcc-14.2.0"}"
GCC_VERSION="${GCC_RELEASE##releases\/}"

RISCV_GCC_VERSION="${RISCV_GCC_VERSION:-"2025.01.20"}"
RISCV_GCC_PREFIX="${RISCV_GCC_PREFIX:-"/opt/gcc${GCC_VERSION}-rp2350-no-zcmp_${RISCV_GCC_VERSION}"}"
RISCV_GCC_BUILDDIR="$(mktemp -d)"

cleanup() {
  apt_clean
  rm -rf "${RISCV_GCC_BUILDDIR}"
}

trap cleanup EXIT

# Common vars
#####################

# Install prerequisites for RISC-V GNU Compiler Toolchain
# https://github.com/riscv-collab/riscv-gnu-toolchain
as_root apt-get update && apt-get -y upgrade
as_root apt-get install -y --no-install-recommends \
  build-essential gperf libtool patchutils bc \
  autoconf automake autotools-dev \
  cmake ninja-build \
  curl git gawk bison flex texinfo \
  python3 python3-pip python3-tomli \
  libmpc-dev libmpfr-dev libgmp-dev zlib1g-dev libexpat-dev libglib2.0-dev libslirp-dev

# Clone and build the RISC-V GCC
git clone --depth 1 --branch "${RISCV_GCC_VERSION}" https://github.com/riscv/riscv-gnu-toolchain "${RISCV_GCC_BUILDDIR}"
git clone --depth 1 --branch "${GCC_RELEASE}" https://github.com/gcc-mirror/gcc "${RISCV_GCC_BUILDDIR}/${GCC_VERSION}"

pushd "${RISCV_GCC_BUILDDIR}"
./configure --prefix="${RISCV_GCC_PREFIX}" \
    --with-arch=rv32ima_zicsr_zifencei_zba_zbb_zbs_zbkb_zca_zcb --with-abi=ilp32 \
    --with-multilib-generator="rv32ima_zicsr_zifencei_zba_zbb_zbs_zbkb_zca_zcb-ilp32--;rv32imac_zicsr_zifencei_zba_zbb_zbs_zbkb-ilp32--" \
    --with-gcc-src="${RISCV_GCC_BUILDDIR}/${GCC_VERSION}"

# shellcheck disable=SC2046
make -j$(nproc)
popd

{
cat <<EOF
export PATH=${RISCV_GCC_PREFIX}/bin\${PATH:+:\$PATH}
EOF
} | as_root tee -a /etc/bash.bashrc
