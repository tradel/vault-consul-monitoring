Monitoring Vault and Consul
===========================

This project uses [Vagrant][] and [VirtualBox][] to spin up a [Vault][]
cluster and a [Consul][] cluster on your own machine, with telemetry collected
by [Telegraf][] and forwarded to [InfluxDB][] and [Grafana][] for analysis.

## Prerequisites

Make sure you have the enterprise binaries for Vault and Consul. The filenames
should look similar to this:

    consul-enterprise_1.0.5+ent_linux_amd64.zip
    vault-enterprise_0.9.3+prem_linux_amd64.zip

## Setup

 1. Clone this project from Github.
 2. Place the Consul and Vault binaries into the project folder.
 3. Run `vagrant up` and wait a while.
 4. Open http://localhost:3000/ in your browser. Log in as **admin/admin**.
 5. Enjoy!
 
## Future Enhancements

 1. Provide sample dashboards out of the box.
 2. Send output to CloudWatch, DataDog, and other systems.

[Vagrant]: https://www.vagrantup.com/
[VirtualBox]: https://www.virtualbox.org/
[Vault]: https://www.vaultproject.io/
[Consul]: https://www.consul.io/
[Telegraf]: https://www.influxdata.com/time-series-platform/telegraf/
[InfluxDB]: https://www.influxdata.com/
[Grafana]: https://grafana.com/
