
data "openstack_images_image_v2" "ubuntu" {
  name        = "Ubuntu 22.04"
  most_recent = true
}

data "openstack_compute_flavor_v2" "master_flavor" {
  name = "ds2G"
}

data "openstack_compute_flavor_v2" "worker_flavor" {
  name = "ds1G"
}

data "openstack_networking_network_v2" "private_network" {
  name = "private"
}

data "openstack_networking_network_v2" "public_network" {
  name = "public"
}

resource "random_password" "k3s_token" {
  length  = 32
  special = false
}

resource "openstack_networking_floatingip_v2" "instance_fip" {
  pool = data.openstack_networking_network_v2.public_network.name
}

resource "openstack_networking_secgroup_v2" "ssh_ping" {
  name        = "allow-ssh-ping-k8s"
  description = "Allows incoming SSH, ICMP, K8s API and internal cluster traffic"
}

resource "openstack_networking_secgroup_rule_v2" "allow_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.ssh_ping.id
}

resource "openstack_networking_secgroup_rule_v2" "allow_ping" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.ssh_ping.id
}

resource "openstack_networking_secgroup_rule_v2" "allow_k8s_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.ssh_ping.id
}

resource "openstack_networking_secgroup_rule_v2" "allow_internal_tcp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_group_id   = openstack_networking_secgroup_v2.ssh_ping.id
  security_group_id = openstack_networking_secgroup_v2.ssh_ping.id
}

resource "openstack_networking_secgroup_rule_v2" "allow_internal_udp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_group_id   = openstack_networking_secgroup_v2.ssh_ping.id
  security_group_id = openstack_networking_secgroup_v2.ssh_ping.id
}

resource "openstack_compute_keypair_v2" "admin_key" {
  name       = "admin-ssh-key-k8s"
  public_key = var.ssh_public_key != "" ? var.ssh_public_key : file(pathexpand("~/.ssh/id_ed25519.pub"))
}

resource "openstack_networking_port_v2" "master_port" {
  name               = "k8s-master-port"
  network_id         = data.openstack_networking_network_v2.private_network.id
  security_group_ids = [openstack_networking_secgroup_v2.ssh_ping.id]
}

resource "openstack_compute_instance_v2" "k8s_master" {
  name      = "k8s-master"
  image_id  = data.openstack_images_image_v2.ubuntu.id
  flavor_id = data.openstack_compute_flavor_v2.master_flavor.id
  key_pair  = openstack_compute_keypair_v2.admin_key.name

  network {
    port = openstack_networking_port_v2.master_port.id
  }

  user_data = <<-EOF
    #!/bin/bash
    curl -sfL https://get.k3s.io | K3S_TOKEN="${random_password.k3s_token.result}" sh -s - server --cluster-init --tls-san ${openstack_networking_floatingip_v2.instance_fip.address}
  EOF
}

resource "openstack_networking_port_v2" "worker_port" {
  name               = "k8s-worker-port"
  network_id         = data.openstack_networking_network_v2.private_network.id
  security_group_ids = [openstack_networking_secgroup_v2.ssh_ping.id]
}

resource "openstack_compute_instance_v2" "k8s_worker" {
  name      = "k8s-worker"
  image_id  = data.openstack_images_image_v2.ubuntu.id
  flavor_id = data.openstack_compute_flavor_v2.worker_flavor.id
  key_pair  = openstack_compute_keypair_v2.admin_key.name

  network {
    port = openstack_networking_port_v2.worker_port.id
  }

  user_data = <<-EOF
    #!/bin/bash
    curl -sfL https://get.k3s.io | K3S_TOKEN="${random_password.k3s_token.result}" K3S_URL="https://${openstack_networking_port_v2.master_port.all_fixed_ips[0]}:6443" sh -
  EOF

  depends_on = [openstack_compute_instance_v2.k8s_master]
}

resource "openstack_networking_floatingip_associate_v2" "fip_association" {
  floating_ip = openstack_networking_floatingip_v2.instance_fip.address
  port_id     = openstack_networking_port_v2.master_port.id
}
