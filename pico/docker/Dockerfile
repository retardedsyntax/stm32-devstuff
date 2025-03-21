# syntax=docker/dockerfile-upstream:master
#################################################
### Base image ###

FROM ubuntu:24.04 AS base_image
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-l", "-eo", "pipefail", "-c"]

# Setup default locale and timezone
ENV TZ='Europe/Helsinki' \
    LANG='en_US.UTF-8' \
    LANGUAGE='en_US:en:C' \
    LC_ALL='C.UTF-8'

RUN apt-get -y update \
    && apt-get -y upgrade \
    && apt-get install -y --no-install-recommends tzdata locales \
    && sed -i -e 's/# C.UTF-8 UTF-8/C.UTF-8 UTF-8/' /etc/locale.gen \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
    && dpkg-reconfigure --frontend=noninteractive tzdata

# Install some basic tools
RUN apt-get -y update \
    && apt-get install -y --no-install-recommends \
    iproute2 iputils-ping net-tools hostname traceroute \
    curl wget ca-certificates \
    bzip2 unzip xz-utils tar \
    git git-lfs gnupg2 \
    nano jq \
    pv sudo openssh-client \
    shellcheck shfmt clang-format clang-tidy \
    build-essential bc gawk bison flex texinfo yacc pkg-config \
    python3 python3-dev python3-venv python3-pip python-is-python3 pipx \
    && apt-get -y clean autoclean \
    && apt-get -y autoremove --purge \
    && rm -rf /var/lib/apt/lists/*

#################################################


#################################################
### RISC-V GCC intermediate image ###

FROM base_image AS setup_riscv_gcc
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-l", "-eo", "pipefail", "-c"]

ARG GCC_VERSION="14.2.0"
ARG GCC_RELEASE="releases/gcc-${GCC_VERSION}"
ARG RISCV_GCC_VERSION="2025.01.20"
ARG RISCV_GCC_PREFIX="/opt/gcc${GCC_VERSION}-rp2350-no-zcmp_${RISCV_GCC_VERSION}"
ARG RISCV_GCC_BUILDDIR="/tmp/riscv-build"

# Install prerequisites for RISC-V GNU Compiler Toolchain
# https://github.com/riscv-collab/riscv-gnu-toolchain
RUN apt-get -y update \
    && apt-get install -y --no-install-recommends \
    build-essential gperf libtool patchutils bc \
    autoconf automake autotools-dev \
    cmake ninja-build \
    curl git gawk bison flex texinfo \
    python3 python3-pip python3-tomli \
    libmpc-dev libmpfr-dev libgmp-dev zlib1g-dev libexpat-dev libglib2.0-dev libslirp-dev \
    && apt-get -y clean autoclean \
    && apt-get -y autoremove --purge \
    && rm -rf /var/lib/apt/lists/*

# Clone and build the RISC-V GCC
RUN git clone --depth 1 --branch "${RISCV_GCC_VERSION}" https://github.com/riscv/riscv-gnu-toolchain "${RISCV_GCC_BUILDDIR}" \
    && git clone --depth 1 --branch "${GCC_RELEASE}" https://github.com/gcc-mirror/gcc "${RISCV_GCC_BUILDDIR}/${GCC_VERSION}" \
    && cd "${RISCV_GCC_BUILDDIR}" \
    && ./configure --prefix="${RISCV_GCC_PREFIX}" \
        --with-arch=rv32ima_zicsr_zifencei_zba_zbb_zbs_zbkb_zca_zcb --with-abi=ilp32 \
        --with-multilib-generator="rv32ima_zicsr_zifencei_zba_zbb_zbs_zbkb_zca_zcb-ilp32--;rv32imac_zicsr_zifencei_zba_zbb_zbs_zbkb-ilp32--" \
        --with-gcc-src="${RISCV_GCC_BUILDDIR}/${GCC_VERSION}" \
    && make -j$(nproc) \
    && rm -rf "${RISCV_GCC_BUILDDIR}"
    
ENV PATH="${RISCV_GCC_PREFIX}/bin:$PATH"

#################################################


#################################################
### SDK image ###

FROM base_image AS sdk_setup
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-l", "-eo", "pipefail", "-c"]

# Install RISC-V GCC
COPY --from=setup_riscv_gcc "${RISCV_GCC_PREFIX}" "${RISCV_GCC_PREFIX}"
ENV PATH="${RISCV_GCC_PREFIX}/bin:$PATH"

# Ensure that /usr/local exists
#RUN mkdir -pv /usr/local

# Install prerequisites for PicoSDK
# https://github.com/raspberrypi/pico-sdk
RUN apt-get -y update \
    && apt-get install -y --no-install-recommends \
    cmake python3 build-essential \
    gcc-arm-none-eabi libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib

# Setup PicoSDK
ARG PICOSDK_VERSION="2.1.1"
ARG PICOSDK_PATH="/usr/local/picosdk"

RUN git clone --depth 1 --branch "${PICOSDK_VERSION}" https://github.com/raspberrypi/pico-sdk.git "${PICOSDK_PATH}" \
    && cd "${PICOSDK_PATH}" \
    && git submodule update --init
ENV PICO_SDK_PATH="${PICOSDK_PATH}"

# Install prerequisites for Picotool
# https://github.com/raspberrypi/picotool
RUN apt-get -y update \
    && apt-get install -y --no-install-recommends \
    build-essential pkg-config libusb-1.0-0-dev cmake

# Clone and build Picotool
ARG PICOTOOL_VERSION="2.1.1"
ARG PICOTOOL_PREFIX="/usr/local"
ARG PICOTOOL_BUILDDIR="/tmp/picotool-build"

RUN git clone --depth 1 --branch "${PICOTOOL_VERSION}" https://github.com/raspberrypi/picotool.git "${PICOTOOL_BUILDDIR}" \
    && cd "${PICOTOOL_BUILDDIR}" \
    && mkdir build && cd build \
    && cmake -DCMAKE_INSTALL_PREFIX="${PICOTOOL_PREFIX}" .. \
    && make -j$(nproc) \
    && cmake --install . \
    && rm -rf "${PICOTOOL_BUILDDIR}"

# Setup FreeRTOS
ARG FREERTOS_VERSION="V11.2.0"
ARG FREERTOS_PATH="/usr/local/freertos-${FREERTOS_VERSION//V/}"

RUN git clone --depth 1 --branch "${FREERTOS_VERSION}" https://github.com/FreeRTOS/FreeRTOS-Kernel "${FREERTOS_PATH}" \
    && cd "${FREERTOS_PATH}" \
    && git submodule update --init --recursive
ENV FREERTOS_KERNEL_PATH="${FREERTOS_PATH}"

# Add some misc tools
RUN apt-get -y update \
    && apt-get install -y --no-install-recommends \
    clangd gdb-multiarch \
    && apt-get -y clean autoclean \
    && apt-get -y autoremove --purge \
    && rm -rf /var/lib/apt/lists/*

#################################################


#################################################
### Builder image ###

FROM sdk_setup AS builder
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-l", "-eo", "pipefail", "-c"]

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Newer ubuntu images contain default user 'ubuntu' which
# usually conflicts with UID 1000.
RUN userdel -r ubuntu \
    && groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} --create-home --no-user-group --shell "/bin/bash" ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}

# Add GEF https://github.com/hugsy/gef
RUN curl -fsSL -o $HOME/.gdbinit-gef.py https://gef.blah.cat/py \
    && echo "source $HOME/.gdbinit-gef.py" >> "$HOME/.gdbinit"

#ENTRYPOINT ["bash"]
#CMD [""]

#################################################