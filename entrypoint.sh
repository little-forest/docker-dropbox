#!/bin/sh

# Chech environment values
if [ -z "${DBOX_USER}" ]; then
  echo "[FATAL] DBOX_USER is not defined." >&2
  exit 1
fi

if [ -z "${USER_ID}" ]; then
  echo "[FATAL] USER_ID is not defined." >&2
  exit 1
fi

if [ -z "${GROUP_ID}" ]; then
  echo "[WARNING] GROUP_ID is not defined. Use USER_ID(${USER_ID}) as GROUP_ID." >&2
fi

USER_NAME=${DBOX_USER}
GROUP_NAME=${USER_NAME}
USER_HOME=/home/${USER_NAME}

echo "Starting dropboxd with UID : ${USER_ID}, GID: ${GROUP_ID}"

# Change UID & GID
groupmod -g ${GROUP_ID} ${GROUP_NAME}
usermod -g ${GROUP_ID} -u ${USER_ID} ${USER_NAME}
chown ${USER_NAME}:${GROUP_NAME} ${USER_HOME} ${USER_HOME}/bin ${USER_HOME}/.dropbox-dist

# Create group and user
export HOME=${USER_HOME}

# Check filesystem
FILESYSTEM=`df -T ${USER_HOME}/Dropbox/ | tail -n1 | awk '{print $2}'`
if [ "$FILESYSTEM" != ext4 ]; then
  echo "[FATAL] Dropbox supports filesystem only ext4. (${USER_HOME}/Dropbox/ is ${FILESYSTEM}" >&2
  exit 1
fi

# Execute dropboxd
su-exec ${USER_NAME} ${USER_HOME}/.dropbox-dist/dropboxd

# vim: ts=2 sw=2 sts=2 et nu foldmethod=marker
