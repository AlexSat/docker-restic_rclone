FROM alpine:latest

ARG ARCH
ARG RCLONE_VERSION=1.59.1
ARG RESTIC_VERSION=0.14.0
ARG OVERLAY_VERSION=v2.2.0.3
ARG OVERLAY_ARCH

ENV TZ Europe/Brussels

WORKDIR /restic

# install restic, rclone, tzdata, python3 and apprise
ARG RESTIC_URL=https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_linux_${ARCH}.bz2
ARG RCLONE_URL=https://github.com/rclone/rclone/releases/download/v${RCLONE_VERSION}/rclone-v${RCLONE_VERSION}-linux-${ARCH}.zip

# from https://github.com/jasonccox/restic-rclone-docker
RUN wget -O - $RESTIC_URL | bzip2 -d -c > /bin/restic && \
    wget -O rclone.zip $RCLONE_URL && \
    unzip rclone.zip && \
    mv rclone-*/rclone /bin/rclone && \
    chmod +x /bin/restic /bin/rclone && \
    rm -rf rclone.zip rclone-* && \
    apk add --no-cache --update tzdata tini python3 git py-pip logrotate shadow bash wget && \
    pip3 install -U pip && \
    pip3 install git+https://github.com/NiNiyas/apprise && \
    apk --purge del git

COPY /root /
RUN chmod +x /usr/local/bin/start.sh && \
    chmod +x /usr/local/bin/restic.sh && \
    cp /opt/rclone /etc/logrotate.d/rclone && \
    cp /opt/restic /etc/logrotate.d/restic

# add s6 overlay from https://github.com/linuxserver/docker-baseimage-alpine
ADD https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}-installer /tmp/
RUN chmod +x /tmp/s6-overlay-${OVERLAY_ARCH}-installer && /tmp/s6-overlay-${OVERLAY_ARCH}-installer / && rm /tmp/s6-overlay-${OVERLAY_ARCH}-installer

RUN addgroup -S restic && adduser -S restic -G restic

VOLUME [ "/config", "/data", "/logs" ]

LABEL GITHUB=https://github.com/NiNiyas/docker-restic_rclone
LABEL MAINTAINER=NiNiyas
LABEL FORKED_FROM=https://github.com/jasonccox/restic-rclone-docker
LABEL org.opencontainers.image.source https://github.com/NiNiyas/docker-restic_rclone

CMD ["/sbin/tini", "-v", "--", "/usr/local/bin/start.sh"]
ENTRYPOINT ["/init"]
