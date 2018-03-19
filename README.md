Monitoring Vault and Consul
===========================

This project uses [Vagrant][] and [VirtualBox][] to spin up a [Vault][]
cluster and a [Consul][] cluster on your own machine, with telemetry collected
by [Telegraf][] and forwarded to [InfluxDB][] and [Grafana][] for analysis.

![Sample Consul Dashboard](https://i.imgur.com/iAXyKKk.png)

## Prerequisites

Make sure you have the enterprise binaries for Vault and Consul. The filenames
should look similar to this:

    consul-enterprise_1.0.5+ent_linux_amd64.zip
    vault-enterprise_0.9.3+prem_linux_amd64.zip

## Setup

 1. Clone this project from Github.
 2. Place the Consul and Vault binaries into the project folder.
 3. Run `vagrant up` and wait a while.
 4. Log into one of the Vault servers and initialize the cluster:

        $ vagrant ssh vault0
        export VAULT_ADDR=http://localhost:8200
        vault operator init
        vault operator unseal ...

## Configuring Grafana

 1. Open http://localhost:3000/ in your browser.
 2. You will be prompted to create your first data source. Configure the
    connection as follows:  

    | Field             | Value                 |
    | ----------------- | --------------------- |
    | Connection String | http://localhost:8086 |
    | Name              | InfluxDB              |
    | Username          | telegraf              |
    | Password          | telegraf              |
    | Telegraf Database | telegraf              |

 3. Click the Home menu at the top of the Grafana home page, and select **Import
    dashboard**. Browse to the location of `vault_cluster_health.json` and
    import it. Do the same for `consul_cluster_health.json`.

## Future Enhancements

 * [x] ~~Provide sample dashboards out of the box.~~
 * [ ] Explain how to send output to CloudWatch, DataDog, and other systems.
 * [ ] Demonstrate alerting and proper thresholds.

[Vagrant]: https://www.vagrantup.com/
[VirtualBox]: https://www.virtualbox.org/
[Vault]: https://www.vaultproject.io/
[Consul]: https://www.consul.io/
[Telegraf]: https://www.influxdata.com/time-series-platform/telegraf/
[InfluxDB]: https://www.influxdata.com/time-series-platform/influxdb/
[Grafana]: https://grafana.com/
