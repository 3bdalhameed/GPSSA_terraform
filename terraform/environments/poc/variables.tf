variable "prefix" {
  type        = string
  description = "Short prefix used in all resource names (e.g. gpssa)"
  default     = "gpssa"
}

variable "project" {
  type        = string
  description = "Project tag value"
  default     = "gpssa-poc"
}

variable "location" {
  type        = string
  description = "Azure region for all POC resources"
  default     = "uaenorth"
}

variable "vpn_shared_key" {
  type        = string
  description = "Pre-shared key for the IPsec VPN tunnel (keep it secret)"
  sensitive   = true
}

variable "vm_admin_username" {
  type        = string
  description = "Admin username for both test VMs"
  default     = "azureuser"
}

variable "vm_ssh_public_key" {
  type        = string
  description = "SSH public key content (e.g. contents of ~/.ssh/id_rsa.pub)"
}

variable "gpssa_sim_ssh_source_ip" {
  type        = string
  description = "Your public IP (or CIDR) allowed to SSH into the GPSSA-sim test VM. Use 'x.x.x.x/32' for a single IP."
  default     = "*"
}
