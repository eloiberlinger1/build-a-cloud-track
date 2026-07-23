output "master_public_ip" {
  description = "The public IP address of the K8s Master"
  value       = openstack_networking_floatingip_v2.instance_fip.address
}

output "master_private_ip" {
  description = "Private IP of K8s Master"
  value       = openstack_networking_port_v2.master_port.all_fixed_ips[0]
}

output "worker_private_ip" {
  description = "Private IP of K8s Worker"
  value       = openstack_networking_port_v2.worker_port.all_fixed_ips[0]
}

output "kubectl_command" {
  description = "Command to retrieve the kubeconfig from your local machine"
  value       = "ssh -o StrictHostKeyChecking=no ubuntu@${openstack_networking_floatingip_v2.instance_fip.address} 'sudo cat /etc/rancher/k3s/k3s.yaml' > kubeconfig.yaml && sed -i '' 's/127.0.0.1/${openstack_networking_floatingip_v2.instance_fip.address}/g' kubeconfig.yaml && export KUBECONFIG=./kubeconfig.yaml"
}
