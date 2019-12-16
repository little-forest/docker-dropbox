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

echo '--------------------------------------------------------------------------------'
echo -e "${C_CYAN}Starting Docker-Dropbox with UID : ${USER_ID}, GID: ${GROUP_ID}${C_OFF}"

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
echo -e "${C_CYAN}Downloading Dropbox...${C_OFF}"
( cd ${USER_HOME} && wget -q -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf - )
if [ -d ${USER_HOME}/.dropbox-dist ]; then
  echo -e "${C_CYAN}Dropbox version is `cat ${USER_HOME}/.dropbox-dist/VERSION`${C_OFF}"
else
  fatal "Unable to download dropboxd"
fi

( cd ${USER_HOME}/bin && wget -q -O dropbox.py "https://www.dropbox.com/download?dl=packages/dropbox.py" )
if [ -f ${USER_HOME}/bin/dropbox.py ]; then
  chmod +x ${USER_HOME}/bin/dropbox.py
else
  fatal "Unable to download dropbox.py"
fi

## Execute Dropbox daemon
echo -e "${C_CYAN}Starting dropbox daemon${C_OFF}"
su-exec ${USER_NAME} ${USER_HOME}/.dropbox-dist/dropboxd &

# Check Dropbox daemon's pid
for T in 1 1 2 3 5 8 13 21 34 55; do
  echo -e "${C_WHITE}Wating for Dropbox daemon to be ready $T seconds...${C_OFF}"
  sleep $T
  if [ -f ${PID_FILE} ]; then
    DROPBOX_PID=`cat ${PID_FILE}`
    echo -e "${C_GREEN}Dropbox daemon detected. pid:${DROPBOX_PID}${C_OFF}"
    su-exec ${USER_NAME} ${USER_HOME}/bin/dropbox.py version
    break
  fi
done
if [ -z "${DROPBOX_PID}" ]; then
  fatal "Unable to detect Dropbox daemon."
fi

# set lansync
if su-exec ${USER_NAME} ${USER_HOME}/bin/dropbox.py lansync ${LANSYNC}; then
  echo -e "${C_GREEN}Set lancync mode to '${LANSYNC}${C_OFF}'"
fi

# Wait to terminate
while :; do
  sleep 5
  ps | awk '{print $1}' | grep -qE "^[ \t]*${DROPBOX_PID}$" || break;
done
echo -e "${C_RED}Detected Dropbox daemon abnormally terminated.${C_OFF}"
exit 1

# vim: ts=2 sw=2 sts=2 et nu foldmethod=marker
