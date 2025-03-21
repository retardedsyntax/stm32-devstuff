#! /usr/bin/env bash
#
# Copyright 2020, Data61/CSIRO
#
# SPDX-License-Identifier: BSD-2-Clause
#

set -exuo pipefail

####################################################################
# Setup user and groups for inside the container

: "${GROUPNAME:-${USERNAME}}"

# It seems that clashes with group names or GIDs is more common
# than one might think. Here we attempt to make a matching group
# inside the container, but if it fails, we abandon the attempt.

# Try to create the group to match the GID. If a group already exists
# with that name, but a different GID, no change will be made.
# We therefore run groupmod to ensure the GID does match what was
# requested.
# However, either of these steps could fail - but if they do,
# that's OK.
groupadd --force --gid "${USER_GID}" "${GROUPNAME}" || true
groupmod --gid "${USER_GID}" "${GROUPNAME}" || true

# Split the group info into an array
IFS=":" read -r -a group_info <<<"$(getent group "${GROUPNAME}")"
fgroup="${group_info[0]}"
fgid="${group_info[2]}"

GROUP_OK=false
if [[ "$fgroup" == "${GROUPNAME}" ]] && [[ "$fgid" == "${USER_GID}" ]]; then
  # This means the group creation has gone OK, so make a user
  # with the corresponding group
  GROUP_OK=true
fi
unset fgroup fgid

if [[ "${GROUP_OK:-false}" == true ]]; then
  useradd --uid "${USER_UID}" --gid "${USER_GID}" --shell "/bin/bash" "${USERNAME}"
else
  # If creating the group didn't work well, that's OK, just
  # make the user without the same group as the host. Not as
  # nice, but still works fine.
  useradd --uid "${USER_UID}" --shell "/bin/bash" "${USERNAME}"
fi

# Remove the user's password
passwd --delete "${USERNAME}"

####################################################################
# Setup sudo for inside the container

cat <<EOF >>/etc/sudoers.d/"${USERNAME}"
${USERNAME} ALL=(ALL:ALL) NOPASSWD: ALL
EOF
chmod 0440 /etc/sudoers.d/"${USERNAME}"

####################################################################
# Setup home dir

# NOTE: the user's home directory is stored in a docker volume.
#       (normally called $USERNAME_home on the host)
#       That implies that these instructions will only run if said
#       docker volume does not exist. Therefore, if the below
#       changes, users will only see the effect if they run:
#          docker volume rm $USERNAME_home

mkdir -pv "/home/${USERNAME}"

# Since the user home is mounted as a volume, we do not write to ~/.bashrc, but
# modify the system-wide bashrc instead. /etc/profile.d/ does not work, because
# it's not a login shell.
#
# When the dockerfiles are building, many of the env settings are written into
# /root/.bashrc by various install tools. We copy all those declarations.
RC_FILE="/etc/bash.bashrc"
grep "export" /root/.bashrc >>"${RC_FILE}"

# The following are in addition to the declarations in /root/.bashrc. Note that
# this block does not do parameter expansion, so will be copied verbatim.
#cat << 'EOF' >> "${RC_FILE}"
#export PATH=/scripts/repo:$PATH
#EOF

# Set an appropriate chown setting, based on if the group setup went OK
chown_setting="${USERNAME}"
if [[ "${GROUP_OK:-false}" == true ]]; then
  chown_setting="${USERNAME}:${GROUPNAME}"
fi

# Make sure the user owns their home dir
chown -Rv "$chown_setting" "/home/${USERNAME}"
chmod -Rv ug+rw "/home/${USERNAME}"
