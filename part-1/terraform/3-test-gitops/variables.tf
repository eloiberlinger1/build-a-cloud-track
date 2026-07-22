variable "openstack_auth_url" {
  type        = string
  description = "URL auth url"
}

variable "openstack_user_name" {
  type        = string
  default     = "admin"
}

variable "openstack_tenant_name" {
  type        = string
  default     = "demo"
}

variable "openstack_password" {
  type        = string
  sensitive   = true
}

variable "openstack_region" {
  type        = string
  default     = "RegionOne"
}

variable "openstack_insecure" {
  type        = bool
  default     = true
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key content"
  default     = ""
}
