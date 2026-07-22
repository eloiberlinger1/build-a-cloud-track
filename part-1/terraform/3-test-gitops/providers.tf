terraform {
  required_version = ">= 1.0"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket                      = "devstack-terraform-state"
    key                         = "terraform.tfstate"
    region                      = "us-east-1"
    endpoints                   = { s3 = "https://s3.eloi-berlinger.ovh" }
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}

provider "openstack" {
  auth_url    = var.openstack_auth_url
  user_name   = var.openstack_user_name
  tenant_name = var.openstack_tenant_name
  password    = var.openstack_password
  region      = var.openstack_region
  insecure    = var.openstack_insecure
}
