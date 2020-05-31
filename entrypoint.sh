#!/bin/sh

DAEMON_VERSION=86.4.146
CLI_VERSION=2019.02.14

PREFERRED_DROPBOX_FILE=dropbox-lnx.x86_64-${DAEMON_VERSION}.tar.gz
DROPBOX_DOWNLOAD_URL="https://clientupdates.dropboxstatic.com/dbx-releng/client/${PREFERRED_DROPBOX_FILE}"
DROPBOX_LATEST_DOWNLOAD_URL="https://www.dropbox.com/download?plat=lnx.x86_64"
DROPBOX_CLI_LATEST_URL="https://www.dropbox.com/download?dl=packages/dropbox.py"

LANSYNC=n

#---------------------------------------------------------------------
# Functions
#---------------------------------------------------------------------
C_RED="\e[31m"
C_GREEN="\e[32m"
C_YELLOW="\e[33m"
C_CYAN="\e[36m"
C_WHITE="\e[37;1m"
C_OFF="\e[m"

fatal() {
  echo -e "${C_RED}[FATAL] $1${C_OFF}" >&2
  # prevent for restart by docker/systemd, exit status must be 0
  exit 0
}

warning() {
  echo -e "${C_YELLOW}[WARNING] $1${C_OFF}" >&2
}

handle_sigterm() {
  dropbox_stop SIGTERM
}
trap 'handle_sigterm' SIGTERM

handle_sigkill() {
  dropbox_stop SIGKILL
}
trap 'handle_sigterm' SIGKILL


dropbox_stop() {
  echo -e "${C_CYAN}Received $1${C_OFF}"
  echo -e "${C_CYAN}Terminating Dropbox daemon...${C_OFF}"

  su-exec ${USER_NAME} ${USER_HOME}/bin/dropbox.py stop
  while :; do
    sleep 1
    ps | awk '{print $1}' | grep -qE "^[ \t]*${DROPBOX_PID}$" || break;
  done
  echo -e "${C_CYAN}Dropbox daemon normally terminated.${C_OFF}"
  exit 0
}

#---------------------------------------------------------------------
# Main Process
#---------------------------------------------------------------------
# Chech environment values
[ -z "${DBOX_USER}" ] && fatal "DBOX_USER is not defined."
[ -z "${USER_ID}" ] && fatal "USER_ID is not defined."

[ -z "${GROUP_ID}" ] && warning "GROUP_ID is not defined. Use USER_ID(${USER_ID}) as GROUP_ID."

USER_NAME=${DBOX_USER}
GROUP_NAME=${USER_NAME}
USER_HOME=/home/${USER_NAME}
DROPBOX_ARCHIVE=${USER_HOME}/.dropbox/archive

echo '--------------------------------------------------------------------------------'
echo -e "${C_CYAN}Starting Docker-Dropbox with UID : ${USER_ID}, GID: ${GROUP_ID}${C_OFF}"
echo -e "Prefered version : ${PREFERRED_DROPBOX_FILE} / ${CLI_VERSION}"

# Change UID & GID
groupmod -g ${GROUP_ID} ${GROUP_NAME}
usermod -g ${GROUP_ID} -u ${USER_ID} ${USER_NAME}
chown ${USER_NAME}:${GROUP_NAME} ${USER_HOME} ${USER_HOME}/bin

# Create group and user
export HOME=${USER_HOME}

# Check the filesystem
#FILESYSTEM=`df -T ${USER_HOME}/Dropbox/ | tail -n1 | awk '{print $2}'`
#if [ "$FILESYSTEM" != ext4 ]; then
#  fatal "Dropbox supports filesystem only ext4. (${USER_HOME}/Dropbox/ is ${FILESYSTEM}"
#fi

# Delete old pid file
PID_FILE=${USER_HOME}/.dropbox/dropbox.pid
[ -f ${PID_FILE} ] && rm ${PID_FILE}

# Download Dropbox daemon
[ ! -d "${DROPBOX_ARCHIVE}" ] && mkdir -p ${DROPBOX_ARCHIVE}
DROPBOX_ARCHIVE_PATH=${DROPBOX_ARCHIVE}/${PREFERRED_DROPBOX_FILE}
if [ -f "${DROPBOX_ARCHIVE_PATH}" ]; then
  # restore
  echo -e "${C_CYAN}Restore Dropbox from ${DROPBOX_ARCHIVE_PATH} ...${C_OFF}"
else
  # download
  if [ -n "${DROPBOX_DOWNLOAD_URL}" ]; then
    DL_URL="${DROPBOX_DOWNLOAD_URL}"
  else
    DL_URL=`curl -I -Ls -o /dev/null -w %{url_effective} ${DROPBOX_LATEST_DOWNLOAD_URL}`
  fi
  echo -e "${C_CYAN}Downloading Dropbox from ${DL_URL} ...${C_OFF}"
  (cd ${DROPBOX_ARCHIVE} && curl -Ls -O "${DL_URL}")
  DROPBOX_ARCHIVE_PATH=${DROPBOX_ARCHIVE}/`basename ${DL_URL}`
fi

# Unarchive dropboxd
tar -C ${USER_HOME} -zxf ${DROPBOX_ARCHIVE_PATH}
if [ -d ${USER_HOME}/.dropbox-dist ]; then
  echo -e "${C_CYAN}Dropbox version is `cat ${USER_HOME}/.dropbox-dist/VERSION`${C_OFF}"
else
  fatal "Unable to download dropboxd"
fi

# Prepare dropbox.py (dropbox cli)
DROPBOX_CLI=${USER_HOME}/bin/dropbox.py
if [ -f "${DROPBOX_ARCHIVE}/dropbox.${CLI_VERSION}.py" ]; then
  # restore archived cli
  echo -e "${C_CYAN}Restore archived dropbox cli...${C_OFF}"
  cp -pfv "${DROPBOX_ARCHIVE}/dropbox.${CLI_VERSION}.py" "${DROPBOX_CLI}"
else
  # download latest cli
  echo -e "${C_CYAN}Download dropbox cli from ${DROPBOX_CLI_LATEST_URL} ...${C_OFF}"
  ( cd ${USER_HOME}/bin && curl -Ls -o dropbox.py "${DROPBOX_CLI_LATEST_URL}" )
  if [ -f ${DROPBOX_CLI} ]; then
    chmod +x ${DROPBOX_CLI}
  else
    fatal "Unable to download dropbox.py"
  fi
fi
chown -R ${USER_ID}:${GROUP_ID} ${DROPBOX_ARCHIVE}

## Execute Dropbox daemon
echo -e "${C_CYAN}Starting dropbox daemon${C_OFF}"
su-exec ${USER_NAME} ${USER_HOME}/.dropbox-dist/dropboxd &
sleep 3

# Check Dropbox daemon's pid
for T in 1 1 2 3 5 8 13 21 34 55; do
  echo -e "${C_WHITE}Wating for Dropbox daemon to be ready $T seconds...${C_OFF}"
  sleep $T
  if [ -f ${PID_FILE} ]; then
    DROPBOX_PID=`cat ${PID_FILE}`
    echo -e "${C_GREEN}Dropbox daemon detected. pid:${DROPBOX_PID}${C_OFF}"
    su-exec ${USER_NAME} ${DROPBOX_CLI} version
    CUR_CLI_VERSION=`su-exec ${USER_NAME} ${DROPBOX_CLI} version | sed -nre 's/Dropbox command-line interface version: (.+)/\1/p'`
    # archive current cli
    cp -fp ${DROPBOX_CLI} ${DROPBOX_ARCHIVE}/dropbox.${CUR_CLI_VERSION}.py
    break
  fi
done
if [ -z "${DROPBOX_PID}" ]; then
  fatal "Unable to detect Dropbox daemon."
fi

# set lansync
if su-exec ${USER_NAME} ${DROPBOX_CLI} lansync ${LANSYNC}; then
  echo -e "${C_GREEN}Set lancync mode to '${LANSYNC}${C_OFF}'"
fi

# Wait to terminate
ps | awk '{print $1}' | grep -qE "^[ \t]*${DROPBOX_PID}$" \
  && echo -e "${C_GREEN}Dropbox daemon started.${C_OFF}"
while :; do
  sleep 5
  ps | awk '{print $1}' | grep -qE "^[ \t]*${DROPBOX_PID}$" || break;
done
echo -e "${C_RED}Detected Dropbox daemon abnormally terminated.${C_OFF}"
exit 1

# vim: ts=2 sw=2 sts=2 et nu foldmethod=marker
