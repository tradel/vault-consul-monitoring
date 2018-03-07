#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

#
# Install prerequisites
#

apt-get update
apt-get install -y apt-transport-https ca-certificates curl \
  software-properties-common linux-image-extra-$(uname -r) \
  linux-image-extra-virtual

#
# Install InfluxDB
#

curl -sL https://repos.influxdata.com/influxdb.key | apt-key add -
source /etc/lsb-release
echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
apt-get update && apt-get -y install influxdb

systemctl daemon-reload
systemctl enable influxdb
systemctl restart influxdb

#
# Install Grafana
#

curl -sL https://packagecloud.io/gpg.key | sudo apt-key add -
echo "deb https://packagecloud.io/grafana/stable/debian/ jessie main" | sudo tee /etc/apt/sources.list.d/grafana.list
apt-get update && apt-get -y install grafana

systemctl daemon-reload
systemctl enable grafana-server
systemctl restart grafana-server
