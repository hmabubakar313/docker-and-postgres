FROM influxdb:1.5.1
# ADD influxdb.conf /etc/influxdb/
# ADD create_db.iql /docker-entrypoint-initdb.d/
FROM debian:stretch-slim
# LABEL maintainer="Phil Hawthorne <me@philhawthorne.com>"

ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8

# Default versions
ENV INFLUXDB_VERSION=1.8.2
ENV CHRONOGRAF_VERSION=1.8.6
ENV GRAFANA_VERSION=7.2.0

# Grafana database type
ENV GF_DATABASE_TYPE=sqlite3

# Fix bad proxy issue
COPY system/99fixbadproxy /etc/apt/apt.conf.d/99fixbadproxy

WORKDIR /root
# RUN mkdir /usr/share/collectd

# Clear previous sources
RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" && \
    case "${dpkgArch##*-}" in \
      amd64) ARCH='amd64';; \
      arm64) ARCH='arm64';; \
      armhf) ARCH='armhf';; \
      armel) ARCH='armel';; \
      *)     echo "Unsupported architecture: ${dpkgArch}"; exit 1;; \
    esac && \
    rm /var/lib/apt/lists/* -vf \
    # Base dependencies
    && apt-get -y update \
    && apt-get -y dist-upgrade \
    && apt-get -y --force-yes install \
        apt-utils \
        ca-certificates \
        curl \
        git \
        htop \
        libfontconfig \
        nano \
        net-tools \
        supervisor \
        wget \
        gnupg \
    && curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && apt-get install -y nodejs \
    && mkdir -p /var/log/supervisor \
    && rm -rf .profile \
    # Install InfluxDB
    && wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb_${INFLUXDB_VERSION}_${ARCH}.deb \
    && dpkg -i influxdb_${INFLUXDB_VERSION}_${ARCH}.deb \
    && rm influxdb_${INFLUXDB_VERSION}_${ARCH}.deb \
    # Install Chronograf
    && wget https://dl.influxdata.com/chronograf/releases/chronograf_${CHRONOGRAF_VERSION}_${ARCH}.deb \
    && dpkg -i chronograf_${CHRONOGRAF_VERSION}_${ARCH}.deb && rm chronograf_${CHRONOGRAF_VERSION}_${ARCH}.deb \
    # Install Grafana
    && wget https://dl.grafana.com/oss/release/grafana_${GRAFANA_VERSION}_${ARCH}.deb \
    && dpkg -i grafana_${GRAFANA_VERSION}_${ARCH}.deb \
    && rm grafana_${GRAFANA_VERSION}_${ARCH}.deb \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure Supervisord and base env
COPY supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY bash/profile .profile

# Configure InfluxDB
COPY influxdb/influxdb.conf /etc/influxdb/influxdb.con
# RUN  systemctl status influxd 
RUN  influx --version
ENV ADMIN_USER root
ENV INFLUXDB_INIT_PWD root
ENV PRE_CREATE_DB **None**
# CMD ["influxd"]
# CMD [ "Create database test" ]
# CMD [ "show databases" ]
# RUN influxd
# RUN systemctl start influxdb
# RUN show databases
# RUN create database test
# RUN show databases
# RUN influx config
# RUN influx config local-config

# RUN influx -username admin -password 123
# RUN Show databases
# RUN CREATE DATABASE test
# RUN create database test

# Configure Grafana
COPY grafana/grafana.ini /etc/grafana/grafana.ini

COPY run.sh /run.sh
RUN ["chmod", "+x", "/run.sh"]
CMD ["/run.sh"]

# RUN influx -host $localhost -port 8086 -username $test -password $123 -ssl -precision rfc3339
# RUN create database test;