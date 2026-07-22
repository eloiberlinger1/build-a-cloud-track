terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.0"
    }
  }
}

provider "openstack" {
  user_name   = "admin"
  tenant_name = "demo"
  password    = "secret"
  auth_url    = "http://192.168.252.3/identity/v3"  
  region      = "RegionOne"
  insecure    = true
}

data "openstack_images_image_v2" "cirros" {
  most_recent = true
}

data "openstack_compute_flavor_v2" "tiny" {
  name = "m1.tiny"
}

data "openstack_networking_network_v2" "private_network" {
  name = "private" 
}

data "openstack_networking_network_v2" "public_network" {
  name = "public"
}

resource "openstack_networking_floatingip_v2" "instance_fip" {
  pool = data.openstack_networking_network_v2.public_network.name
}

resource "openstack_networking_secgroup_v2" "ssh_ping" {
  name        = "allow-ssh-ping"
  description = "Allows incoming SSH and ICMP traffic"
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

resource "openstack_compute_keypair_v2" "admin_key" {
  name       = "admin-ssh-key"
  public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))
}

resource "openstack_networking_port_v2" "instance_port" {
  name               = "tf-instance-port"
  network_id         = data.openstack_networking_network_v2.private_network.id
  security_group_ids = [
    openstack_networking_secgroup_v2.ssh_ping.id
  ]
}

resource "openstack_compute_instance_v2" "terraform_instance" {
  name      = "tf-provisioned-instance"
  image_id  = data.openstack_images_image_v2.cirros.id
  flavor_id = data.openstack_compute_flavor_v2.tiny.id
  key_pair  = openstack_compute_keypair_v2.admin_key.name

  network {
    port = openstack_networking_port_v2.instance_port.id
  }
}

resource "openstack_networking_floatingip_associate_v2" "fip_association" {
  floating_ip = openstack_networking_floatingip_v2.instance_fip.address
  port_id     = openstack_networking_port_v2.instance_port.id
}

output "instance_public_ip" {
  description = "The public IP address of the provisioned instance"
  value       = openstack_networking_floatingip_v2.instance_fip.address
}