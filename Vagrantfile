# coding: utf-8

Vagrant.require_version ">= 1.6.0"

CONSUL_BINARY = "consul-enterprise_1.0.7+ent_linux_amd64.zip"
VAULT_BINARY = "vault-enterprise_0.10.1+ent_linux_amd64.zip"

Vagrant.configure("2") do |config|

  config.vm.define "statsbox", autostart: true do |statsbox|
    statsbox.vm.box = "ubuntu/xenial64"
    statsbox.vm.provider "virtualbox" do |vb|
      vb.linked_clone = true
      vb.memory = "1024"
      vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
    end

    statsbox.vm.hostname = "statsbox"
    statsbox.vm.network "private_network", ip: "10.13.37.10"
    statsbox.vm.network "forwarded_port", guest: 3000, host: 3000 # Graphite UI
    statsbox.vm.network "forwarded_port", guest: 8086, host: 8086 # InfluxDB
    statsbox.vm.network "forwarded_port", guest: 8888, host: 8888 # Chronograf
    statsbox.vm.network "forwarded_port", guest: 9092, host: 9092 # Kapacitor

    statsbox.vm.provision "hosts", autoconfigure: true, sync_hosts: true
    statsbox.vm.provision "shell", path: "statsbox/statsbox.sh"
  end

  %w(consul0 consul1 consul2).each_with_index do |nodename, consul_index|

    config.vm.define "#{nodename}", autostart: true do |thisnode|
      thisnode.vm.box = "ubuntu/xenial64"
      thisnode.vm.provider "virtualbox" do |vb|
        vb.linked_clone = true
        vb.memory = "512"
        vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
      end

      ip_address = "10.13.37.#{20 + consul_index}"

      thisnode.vm.hostname = "#{nodename}"

      thisnode.vm.network "private_network", ip: ip_address

      if "#{nodename}".include? "consul0" then
        thisnode.vm.network "forwarded_port", guest: 8500, host: 8500 # Consul UI
      end

      thisnode.vm.provision "hosts", autoconfigure: true, sync_hosts: true
      thisnode.vm.provision "shell", path: "consul/consul-server.sh"
    end
  end

  %w(vault0 vault1 vault2).each_with_index do |nodename, vault_index|

    config.vm.define "#{nodename}", autostart: true do |thisnode|
      thisnode.vm.box = "ubuntu/xenial64"
      thisnode.vm.provider "virtualbox" do |vb|
        vb.linked_clone = true
        vb.memory = "512"
        vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
      end

      thisnode.vm.hostname = "#{nodename}"

      ip_address = "10.13.37.#{30 + vault_index}"
      
      thisnode.vm.network "private_network", ip: ip_address

      if "#{nodename}".include? "vault0" then
        thisnode.vm.network "forwarded_port", guest: 8200, host: 8200 # Vault UI
        thisnode.vm.provision "shell", path: "vault/databases.sh"
      end

      thisnode.vm.provision "hosts", autoconfigure: true, sync_hosts: true
      thisnode.vm.provision "shell", path: "consul/consul-client.sh"
      thisnode.vm.provision "shell", path: "vault/vault-server.sh"
    end
  end

end
