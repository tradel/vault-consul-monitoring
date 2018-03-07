#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

#
# Install Vault server
#

cd /tmp
apt-get -y install unzip
unzip -o /vagrant/vault-*.zip -d /tmp
install -c -m 0755 /tmp/vault /usr/local/sbin
install -c -m 0644 /vagrant/vault/vault.service /etc/systemd/system
install -d -m 0755 -o vagrant /data/vault /etc/vault.d
install -c -m 0644 /vagrant/vault/vault_server.hcl /etc/vault.d

systemctl daemon-reload
systemctl enable vault
systemctl restart vault
