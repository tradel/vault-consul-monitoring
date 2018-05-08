provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_image" "influxdb" {
  name = "influxdb:alpine"
}

resource "docker_image" "telegraf" {
  name = "telegraf:alpine"
}

resource "docker_image" "consul" {
  name = "consul:latest"
}

resource "docker_image" "vault" {
  name = "vault:latest"
}

resource "docker_container" "influxdb" {
  name = "influxdb"
  image = "${docker_image.influxdb.latest}"
  ports {
    internal = 8086
    external = 8086
  }
}

resource "docker_container" "telegraf" {
  name = "telegraf"
  image = "${docker_image.telegraf.latest}"
  # network_mode = "host"
  links = [
    "influxdb:influxdb"
  ]
  ports {
    internal = 8125
    external = 8125
    protocol = "udp"
  }
  volumes {
    host_path = "${path.module}/consul/telegraf.d/"
    container_path = "/etc/telegraf/"
    read_only = true
  }
}

resource "docker_container" "consul0" {
  name = "consul0"
  image = "${docker_image.consul.latest}"
  env = [
    "CONSUL_BIND_INTERFACE=eth0",
    "CONSUL_CLIENT_INTERFACE=eth0"
  ]
  command = ["consul", "agent", "-server", "-bootstrap-expect=3", "-data-dir=/consul/data"]
  volumes {
    host_path = "${path.module}/consul/consul.d/"
    container_path = "/consul/config/"
  }
  links = [
    "telegraf:telegraf"
  ]
  ports {
    internal = 8500
    external = 8500
  }
}

resource "docker_container" "consul" {
  count = 2
  name = "consul${count.index + 1}"
  image = "${docker_image.consul.latest}"
  env = [
    "CONSUL_BIND_INTERFACE=eth0",
    "CONSUL_CLIENT_INTERFACE=eth0"
  ]
  command = ["consul", "agent", "-server", "-retry-join=${docker_container.consul0.ip_address}", "-data-dir=/consul/data"]
  volumes {
    host_path = "${path.module}/consul/consul.d/"
    container_path = "/consul/config/"
  }
  links = [
    "telegraf:telegraf"
  ]
}
