terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.0"
    }
  }
}

provider "openstack" {
  # acces and auth variables from the ENV
}

resource "openstack_objectstorage_container_v1" "tf_state" {
  name = "devstack-terraform-state"

  lifecycle {
    prevent_destroy = true
  }
}

output "container_name" {
  value       = openstack_objectstorage_container_v1.tf_state.name
  description = "Terraform's backend name"
}
