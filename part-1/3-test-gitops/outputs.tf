output "instance_public_ip" {
  description = "The public IP address of the provisioned instance"
  value       = openstack_networking_floatingip_v2.instance_fip.address
}
