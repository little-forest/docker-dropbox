FROM frolvlad/alpine-glibc

MAINTAINER Yusuke KOMORI <komo@littleforest.jp>

USER root

ARG DBOX_USER="dbox"
ARG DBOX_GROUP=${DBOX_USER}
ENV DBOX_USER  ${DBOX_USER}

RUN apk update && apk add --no-cache ca-certificates wget glib libstdc++ su-exec shadow python3 \
    && apk add openssl \
    && addgroup -g 9999 ${DBOX_GROUP} && adduser -u 9999 -h /home/${DBOX_USER} -s /bin/sh -D -G ${DBOX_GROUP} ${DBOX_USER} \
    && mkdir -p /home/${DBOX_USER}/.dropbox /home/${DBOX_USER}/Dropbox /home/${DBOX_USER}/bin \
    && wget https://www.dropbox.com/download?dl=packages/dropbox.py -O /home/${DBOX_USER}/bin/dropbox.py \
    && chmod +x /home/${DBOX_USER}/bin/dropbox.py \
    && cd /home/${DBOX_USER} && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf - \
    && echo "Installed Dropbox version:" $(cat /home/${DBOX_USER}/.dropbox-dist/VERSION)

COPY entrypoint.sh /
COPY dropbox /

EXPOSE 17500

VOLUME ["/home/${DBOX_USER}/Dropbox", "/home/${DBOX_USER}/.dropbox"]

ENTRYPOINT ["/entrypoint.sh"]

