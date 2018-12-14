#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

apt-get -y install gawk

ipaddr=$(ifconfig | grep enp | awk '{print $1}' | xargs ip addr show dev | awk 'match($0, /inet ([0-9.]*)\/24/, m) { print m[1] }')

#
# Install Consul agent
#

cd /tmp
apt-get -y install unzip
unzip -o /vagrant/consul*.zip -d /tmp
install -c -m 0755 /tmp/consul /usr/local/sbin
install -c -m 0644 /vagrant/consul/consul.service /etc/systemd/system
install -d -m 0755 -o vagrant /data/consul /etc/consul.d
sed -e "s/@@BIND_ADDR@@/${ipaddr}/" < /vagrant/consul/client.json.tmpl > /etc/consul.d/client.json

systemctl daemon-reload
systemctl enable consul
systemctl restart consul
