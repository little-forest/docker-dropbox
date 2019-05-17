#!/bin/sh

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
  exit 1
}

warning() {
  echo -e "${C_YELLOW}[WARNING] $1${C_OFF}" >&2
  exit 1
}

dropbox_stop() {
  echo -e "${C_CYAN}Terminating Dropbox daemon...${C_OFF}"
  su-exec ${USER_NAME} ${USER_HOME}/bin/dropbox.py stop
  while :; do
    sleep 1
    ps | awk '{print $1}' | grep -qE "^[ \t]*${DROPBOX_PID}$" || break;
  done
  echo -e "${C_CYAN}Dropbox daemon terminated.${C_OFF}"
}
trap 'dropbox_stop' EXIT


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

VERSION=`cat ${USER_HOME}/.dropbox-dist/VERSION`

echo '--------------------------------------------------------------------------------'
echo -e "${C_CYAN}Dropbox version : $VERSION${C_OFF}"
echo -e "${C_CYAN}Starting dropboxd with UID : ${USER_ID}, GID: ${GROUP_ID}${C_OFF}"

# Change UID & GID
groupmod -g ${GROUP_ID} ${GROUP_NAME}
usermod -g ${GROUP_ID} -u ${USER_ID} ${USER_NAME}
chown ${USER_NAME}:${GROUP_NAME} ${USER_HOME} ${USER_HOME}/bin ${USER_HOME}/.dropbox-dist

# Create group and user
export HOME=${USER_HOME}

# Check filesystem
FILESYSTEM=`df -T ${USER_HOME}/Dropbox/ | tail -n1 | awk '{print $2}'`
if [ "$FILESYSTEM" != ext4 ]; then
  fatal "Dropbox supports filesystem only ext4. (${USER_HOME}/Dropbox/ is ${FILESYSTEM}"
fi

# Delete old pid file
PID_FILE=${USER_HOME}/.dropbox/dropbox.pid
[ -f ${PID_FILE} ] && rm ${PID_FILE}

# Execute Dropbox daemon
su-exec ${USER_NAME} ${USER_HOME}/bin/dropbox.py start

# Check Dropbox daemon's pid
while :; do
  echo -e "${C_WHITE}Wating for Dropbox daemon to be ready...${C_OFF}"
  sleep 1
  if [ -f ${PID_FILE} ]; then
    DROPBOX_PID=`cat ${PID_FILE}`
    echo -e "${C_GREEN}Dropbox daemon detected. pid:${DROPBOX_PID}${C_OFF}"
    break
  fi
done

# set lansync
if su-exec ${USER_NAME} ${USER_HOME}/bin/dropbox.py lansync ${LANSYNC}; then
  echo -e "${C_GREEN}Set lancync mode to ${LANSYNC}${C_OFF}"
fi

# Wait to terminate
while :; do
  sleep 5
  ps | awk '{print $1}' | grep -qE "^[ \t]*${DROPBOX_PID}$" || break;
done
echo -e "${C_WHITE}Dropbox daemon terminated.${C_OFF}"

# vim: ts=2 sw=2 sts=2 et nu foldmethod=marker
