FROM ubuntu:18.04

LABEL maintainer="Yusuke KOMORI"

USER root

ARG DBOX_USER="dbox"
ARG DBOX_GROUP=${DBOX_USER}
ENV DBOX_USER  ${DBOX_USER}

RUN apt-get update \
    && apt-get -y install --no-install-recommends \
      ca-certificates \
      curl \
      gosu \
      procps \
      python3-gi \
      python3 \
      libatk1.0-0 \
      libc6 \
      libcairo2 \
      libglib2.0-0 \
      libgtk-3-0 \
      libpango1.0-0 \
      lsb-release \
      gir1.2-gdkpixbuf-2.0 \
      gir1.2-glib-2.0 \
      gir1.2-gtk-3.0 \
      gir1.2-pango-1.0 \
      nautilus \
      python3-gpg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g 9999 ${DBOX_GROUP} \
    && mkdir /home/${DBOX_USER} \
    && useradd -u 9999 -G ${DBOX_GROUP} -N -M -d /home/${DBOX_USER} -s /bin/sh ${DBOX_USER} \
    && mkdir -p /home/${DBOX_USER}/.dropbox /home/${DBOX_USER}/Dropbox /home/${DBOX_USER}/bin

COPY dropbox /
COPY entrypoint.sh /

EXPOSE 17500

VOLUME ["/home/${DBOX_USER}/Dropbox", "/home/${DBOX_USER}/.dropbox"]

ENTRYPOINT ["/entrypoint.sh"]

