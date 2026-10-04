FROM debian:trixie-slim

ARG HOMEGEAR_DIST=trixie
# Nightly builds (0.10.x) are currently broken: they require libhomegear-node
# versions the repository no longer ships and abort during shutdown before
# saving peers. Stable 0.9.x runs cleanly.
ARG HOMEGEAR_CHANNEL=stable

RUN apt-get update && apt-get -y install --no-install-recommends \
        wget ca-certificates apt-utils gnupg \
        insserv locales lsb-release \
        openssl logrotate procps \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*

RUN \
    touch /tmp/HOMEGEAR_STATIC_INSTALLATION; \
    touch /.dockerenv; \
    set -e; \
    wget -qO- https://apt.homegear.eu/Release.key | gpg --dearmor > /usr/share/keyrings/homegear.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/homegear.gpg] https://apt.homegear.eu/debian/${HOMEGEAR_DIST}/homegear/${HOMEGEAR_CHANNEL}/ ${HOMEGEAR_DIST} main" > /etc/apt/sources.list.d/homegear.list; \
    apt-get update && apt-get -y install \
        libhomegear-node homegear homegear-management homegear-webssh homegear-adminui homegear-ui \
        homegear-nodes-core homegear-nodes-extra homegear-homematicbidcos homegear-homematicwired \
        homegear-insteon homegear-max homegear-philipshue homegear-sonos homegear-kodi homegear-beckhoff \
        homegear-knx homegear-enocean homegear-intertechno homegear-mbus homegear-zwave homegear-zigbee \
        homegear-ccu homegear-influxdb; \
    rm -f /etc/homegear/dh1024.pem; \
    rm -f /etc/homegear/homegear.crt; \
    rm -f /etc/homegear/homegear.key; \
    cp -a /etc/homegear /etc/homegear.config; \
    cp -a /var/lib/homegear /var/lib/homegear.data; \
    rm -f /etc/logrotate.d/homegear /etc/logrotate.d/homegear-influxdb; \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

COPY script/logrotate.conf /etc/logrotate.d/homegear
COPY script/run.sh /run.sh
RUN chmod 644 /etc/logrotate.d/homegear && chmod +x /run.sh
ENTRYPOINT ["/bin/bash", "-c", "/run.sh"]
