#! /usr/bin/env bash

set -exuo pipefail

# Source common functions with funky bash, as per: https://stackoverflow.com/a/12694189
DIR="${BASH_SOURCE%/*}"
test -d "$DIR" || DIR=$PWD

# shellcheck source=utils/common.sh
. "$DIR/utils/common.sh"

#####################
# Common vars

PICOSDK_VERSION="${PICOSDK_VERSION:-"2.1.1"}"
PICOSDK_PATH="${PICOSDK_PATH:-"/usr/local/picosdk"}"

PICOTOOL_VERSION="${PICOTOOL_VERSION:-"2.1.1"}"
PICOTOOL_PREFIX="${PICOTOOL_PREFIX:-"/usr/local"}"
PICOTOOL_BUILDDIR="$(mktemp -d)"

FREERTOS_VERSION="${FREERTOS_VERSION:-"V11.2.0"}"
FREERTOS_PATH="${FREERTOS_PATH:-"/usr/local/freertos-${FREERTOS_VERSION//V/}"}"

cleanup() {
  apt_clean
  rm -rf "${PICOTOOL_BUILDDIR}"
}

trap cleanup EXIT

# Common vars
#####################

# Install prerequisites for PicoSDK
# https://github.com/raspberrypi/pico-sdk
as_root apt-get update && apt-get -y upgrade
as_root apt-get install -y --no-install-recommends \
  cmake python3 build-essential \
  gcc-arm-none-eabi libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib

# Setup PicoSDK
git clone --depth 1 --branch "${PICOSDK_VERSION}" https://github.com/raspberrypi/pico-sdk.git "${PICOSDK_PATH}"
pushd "${PICOSDK_PATH}"
git submodule update --init --recursive
popd
export PICO_SDK_PATH="${PICOSDK_PATH}"


# Install prerequisites for Picotool
# https://github.com/raspberrypi/picotool
as_root apt-get update && apt-get -y upgrade
as_root apt-get install -y --no-install-recommends \
  build-essential pkg-config libusb-1.0-0-dev cmake

# Clone and build Picotool
git clone --depth 1 --branch "${PICOTOOL_VERSION}" https://github.com/raspberrypi/picotool.git "${PICOTOOL_BUILDDIR}"
pushd "${PICOTOOL_BUILDDIR}"
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX="${PICOTOOL_PREFIX}" ..
# shellcheck disable=SC2046
make -j$(nproc)
cmake --install .
popd

# Setup FreeRTOS
git clone --depth 1 --branch "${FREERTOS_VERSION}" https://github.com/FreeRTOS/FreeRTOS-Kernel "${FREERTOS_PATH}"
pushd "${FREERTOS_PATH}"
git submodule update --init --recursive
popd

# Setup environment variables
{
cat <<EOF
export PICO_SDK_PATH="${PICOSDK_PATH}"
export FREERTOS_KERNEL_PATH="${FREERTOS_PATH}"
EOF
} | as_root tee -a /etc/bash.bashrc
