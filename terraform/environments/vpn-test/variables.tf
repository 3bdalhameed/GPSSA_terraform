variable "location" {
  type        = string
  description = "Azure region — must match shared environment"
  default     = "uaenorth"
}

variable "vpn_shared_key" {
  type        = string
  description = "Pre-shared key for the IPsec tunnel — same value on both sides"
  sensitive   = true
}

variable "vm_admin_username" {
  type    = string
  default = "azureuser"
}

variable "vm_ssh_public_key" {
  type        = string
  description = "Contents of your ~/.ssh/id_rsa.pub"
}

variable "ssh_source_ip" {
  type        = string
  description = "Your public IP (x.x.x.x/32) allowed to SSH into the test VM — find it at https://ifconfig.me"
}
