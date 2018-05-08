variable "vault_port" {
  default = 8200
}

variable "consul_port" {
  default = 8500
}

variable "aws_region" {
  default = "us-east-2"
}

variable "ssh_key_name" {
  default = "tradel"
}

variable "consul_cluster_name" {
  default = "monitoring-test-cluster"
}

variable "consul_cluster_size" {
  default = 3
}

variable "consul_instance_type" {
  default = "t2.small"
}

variable "vault_cluster_size" {
  default = 3
}

variable "vault_instance_type" {
  default = "t2.small"
}

variable "allowed_ssh_cidr_blocks" {
  default = ["0.0.0.0/0"]
}

variable "allowed_inbound_cidr_blocks" {
  default = ["0.0.0.0/0"]
}

#
# Get VPC config from AWS
#

provider "aws" {
  region = "${var.aws_region}"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_availability_zones" "azs" {}

data "aws_internet_gateway" "gw" {
  filter {
    name = "attachment.vpc-id"
    values = ["${data.aws_vpc.default.id}"]
  }
}

data "aws_route53_zone" "cs" {
  name         = "hashicorp-success.com."
  private_zone = false
}

#
# CONSUL
#

module "consul_cluster" {
  source = "github.com/hashicorp/terraform-aws-consul//modules/consul-cluster?ref=v0.3.1"

  ami_id = "ami-30033355"
  vpc_id = "${data.aws_vpc.default.id}"
  availability_zones = ["${data.aws_availability_zones.azs.names}"]
  ssh_key_name = "${var.ssh_key_name}"
  cluster_name = "${var.consul_cluster_name}"
  cluster_size = "${var.consul_cluster_size}"
  instance_type = "${var.consul_instance_type}"
  allowed_ssh_cidr_blocks = ["${var.allowed_ssh_cidr_blocks}"]
  allowed_inbound_cidr_blocks = ["${var.allowed_inbound_cidr_blocks}"]
  cluster_tag_key   = "consul-cluster"
  cluster_tag_value = "${var.consul_cluster_name}"

  # Configure and start Consul during boot. It will automatically form a cluster with all nodes that have that same tag.
  user_data = <<-EOF
              #!/bin/bash
              set -e
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              /opt/consul/bin/run-consul --server --cluster-tag-key "consul-cluster" --cluster-tag-value "${var.consul_cluster_name}"
              EOF
}

resource "aws_security_group" "consul_elb" {
  name        = "consul_elb_sg"
  description = "Allow incoming traffic to Consul"

  vpc_id = "${data.aws_vpc.default.id}"

  # HTTP access from anywhere on port 8200
  ingress {
    from_port   = "${var.consul_port}"
    to_port     = "${var.consul_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.allowed_inbound_cidr_blocks}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ensure the VPC has an Internet gateway or this step will fail
  depends_on = ["data.aws_internet_gateway.gw"]
}

resource "aws_elb" "consul" {
  name               = "consul-elb"
  availability_zones = ["${data.aws_availability_zones.azs.names}"]
  security_groups    = ["${aws_security_group.consul_elb.id}"]

  listener {
    instance_port     = "${var.consul_port}"
    instance_protocol = "http"
    lb_port           = "${var.consul_port}"
    lb_protocol       = "http"
  }

  health_check {
     healthy_threshold   = 2
     unhealthy_threshold = 2
     timeout             = 3
     target              = "HTTP:${var.consul_port}/v1/status/leader"
     interval            = 30
   }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "consul-elb"
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_consul" {
  autoscaling_group_name = "${module.consul_cluster.asg_name}"
  elb                    = "${aws_elb.consul.id}"
}

resource "aws_route53_record" "consul" {
  zone_id = "${data.aws_route53_zone.cs.zone_id}"
  name = "consul.capitalone.${data.aws_route53_zone.cs.name}"
  type = "A"
  alias {
    name = "${aws_elb.consul.dns_name}"
    zone_id = "${aws_elb.consul.zone_id}"
    evaluate_target_health = true
  }
}

#
# VAULT
#

module "vault_cluster" {
  source = "github.com/hashicorp/terraform-aws-vault//modules/vault-cluster?ref=v0.5.0"

  ami_id = "ami-cc0232a9"
  vpc_id = "${data.aws_vpc.default.id}"
  availability_zones = ["${data.aws_availability_zones.azs.names}"]
  ssh_key_name = "${var.ssh_key_name}"
  cluster_name = "${var.consul_cluster_name}"
  cluster_size = "${var.vault_cluster_size}"
  instance_type = "${var.vault_instance_type}"
  allowed_ssh_cidr_blocks = ["${var.allowed_ssh_cidr_blocks}"]
  allowed_inbound_cidr_blocks = ["${var.allowed_inbound_cidr_blocks}"]
  allowed_inbound_security_group_ids = []

  # Configure and start Vault during boot.
  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Send the log output from this script to user-data.log, syslog, and the console
              # From: https://alestic.com/2010/12/ec2-user-data-output/
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

              # The Packer template puts the TLS certs in these file paths
              readonly VAULT_TLS_CERT_FILE="/opt/vault/tls/vault.crt.pem"
              readonly VAULT_TLS_KEY_FILE="/opt/vault/tls/vault.key.pem"

              # The cluster_tag variables below are filled in via Terraform interpolation
              /opt/consul/bin/run-consul --client --cluster-tag-key "consul-cluster" --cluster-tag-value "${var.consul_cluster_name}"
              /opt/vault/bin/run-vault --tls-cert-file "$VAULT_TLS_CERT_FILE"  --tls-key-file "$VAULT_TLS_KEY_FILE"
              EOF
}

resource "aws_security_group" "vault_elb" {
  name        = "vault_elb_sg"
  description = "Allow incoming traffic to Vault"

  vpc_id = "${data.aws_vpc.default.id}"

  # HTTP access from anywhere on port 8200
  ingress {
    from_port   = "${var.vault_port}"
    to_port     = "${var.vault_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.allowed_inbound_cidr_blocks}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ensure the VPC has an Internet gateway or this step will fail
  depends_on = ["data.aws_internet_gateway.gw"]
}

resource "aws_elb" "vault" {
  name               = "vault-elb"
  availability_zones = ["${data.aws_availability_zones.azs.names}"]
  security_groups    = ["${aws_security_group.vault_elb.id}"]

  listener {
    instance_port     = "${var.vault_port}"
    instance_protocol = "http"
    lb_port           = "${var.vault_port}"
    lb_protocol       = "http"
  }

  health_check {
     healthy_threshold   = 2
     unhealthy_threshold = 2
     timeout             = 3
     target              = "HTTP:${var.vault_port}/v1/sys/health"
     interval            = 30
   }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "vault-elb"
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_vault" {
  autoscaling_group_name = "${module.vault_cluster.asg_name}"
  elb                    = "${aws_elb.vault.id}"
}

resource "aws_route53_record" "vault" {
  zone_id = "${data.aws_route53_zone.cs.zone_id}"
  name = "vault.capitalone.${data.aws_route53_zone.cs.name}"
  type = "A"
  alias {
    name = "${aws_elb.vault.dns_name}"
    zone_id = "${aws_elb.vault.zone_id}"
    evaluate_target_health = true
  }
}
