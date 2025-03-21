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
### intermediate image ###

#FROM base_image AS nvm
#SHELL ["/bin/bash", "-l", "-exuo", "pipefail", "-c"]
#
## Create a script file sourced by both interactive and non-interactive bash shells
#ENV NVM_DIR="/usr/local/nvm"
#ENV NVM_ENV="/etc/.nvmenv"
#RUN touch "${NVM_ENV}" \
#    && echo 'source "${NVM_ENV}"' >> /etc/bash.bashrc
#
## Download and install nvm
#RUN mkdir -pv "${NVM_DIR}" \
#    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | PROFILE="${NVM_ENV}" bash \
#    && source "${NVM_DIR}/nvm.sh" \
#    && nvm install --lts node \
#    && nvm use node \
#    && nvm alias default node \
#    && nvm install-latest-npm \
#    && npm install --global xpm@latest

FROM base_image AS arm_gcc
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-l", "-eo", "pipefail", "-c"]

# Install ARM xPack toolchain
ARG ARM_GCC_XPACK_VERSION="14.2.1-1.1"
ARG ARM_GCC_XPACK_ARCHIVE="xpack-arm-none-eabi-gcc-${ARM_GCC_XPACK_VERSION}-linux-x64.tar.gz"
ARG ARM_GCC_XPACK_URL="https://github.com/xpack-dev-tools/arm-none-eabi-gcc-xpack/releases/download/v${ARM_GCC_XPACK_VERSION}/${ARM_GCC_XPACK_ARCHIVE}"
ARG ARM_GCC_XPACK_PATH="/opt/xpack-arm-none-eabi-gcc-${ARM_GCC_XPACK_VERSION}"

RUN curl -fsSL -o "/tmp/${ARM_GCC_XPACK_ARCHIVE}" "${ARM_GCC_XPACK_URL}" \
    && tar -C /opt/ -xvf "/tmp/${ARM_GCC_XPACK_ARCHIVE}" \
    && rm -f "/tmp/${ARM_GCC_XPACK_ARCHIVE}"

#ENV PATH="${ARM_GCC_XPACK_PATH}/bin${PATH:+:$PATH}"

#################################################


#################################################
### SDK image ###

FROM base_image AS sdk
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-l", "-eo", "pipefail", "-c"]

# Install needed packages
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
    libboost-all-dev \
    gdb-multiarch \
    scons \
    libncursesw6 \
    # Hardware related tools
    stlink-tools \
    openocd \
    dfu-util \
    usbutils \
    libusb-1.0-0 libusb-1.0-0-dev libhidapi-libusb0 \
    libhidapi-dev libhidapi-hidraw0 \
    && apt-get -y clean autoclean \
    && apt-get -y autoremove --purge \
    && rm -rf /var/lib/apt/lists/*

# Create venv for python packages to avoid externally managed error
# PYVER="$(python3 -c 'from sys import version_info as ver; print("{}.{}".format(ver[0],ver[1]))')"
RUN python3 -m venv /opt/venv

# Install python packages
RUN PATH="/opt/venv/bin:$PATH" \
    pip3 install \
    setuptools \
    pyelftools \
    python-magic \
    lizard \
    cpplint \
    modm \
    gdbgui

# Copy over the ARM GCC
ARG ARM_GCC_XPACK_VERSION="14.2.1-1.1"
ARG ARM_GCC_XPACK_PATH="/opt/xpack-arm-none-eabi-gcc-${ARM_GCC_XPACK_VERSION}"
COPY --from=arm_gcc "${ARM_GCC_XPACK_PATH}" "${ARM_GCC_XPACK_PATH}"

# Setup environment
#RUN <<EOF /etc/python.bashrc
#PYVER="$$(python3 -c 'from sys import version_info as ver; print("{}.{}".format(ver[0],ver[1]))')"
#export PYTHONPATH="/opt/venv/lib/python${PYVER}/site-packages${PYTHONPATH:+:$PYTHONPATH}"
#EOF
#RUN <<EOF | tee -a /etc/bash.bashrc
#export PATH="${ARM_GCC_XPACK_PATH}/bin:/opt/venv/bin${PATH:+:$PATH}"
#EOF

ENV PATH="${ARM_GCC_XPACK_PATH}/bin:/opt/venv/bin:$PATH"
#ENV PYTHONPATH="/opt/venv/lib/python3.12/site-packages:$PYTHONPATH"
ENV PYTHONPATH="/opt/venv/lib/python3.12/site-packages${PYTHONPATH:+:$PYTHONPATH}"

#################################################


#################################################
### Builder image ###

FROM sdk AS builder
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
