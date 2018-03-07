storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault"
}

listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = true
}

telemetry {
  statsd_address   = "localhost:8125"
  disable_hostname = true
}
