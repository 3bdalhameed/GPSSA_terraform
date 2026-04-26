variable "prefix" {
  type        = string
  description = "Resource prefix (keep consistent with other environments)"
}

variable "location" {
  type        = string
  description = "Azure region (must match shared environment)"
}

variable "vpn_shared_key" {
  type        = string
  description = "Pre-shared key for the IPsec tunnel — must match what you configure on the real GPSSA device"
  sensitive   = true
}

variable "gpssa_sim_vnet_cidr" {
  type        = string
  description = "CIDR for the simulated GPSSA VNet"
  default     = "192.168.0.0/16"
}

variable "gpssa_gateway_subnet_cidr" {
  type        = string
  description = "GatewaySubnet CIDR within gpssa_sim_vnet_cidr (/27 minimum)"
  default     = "192.168.0.0/27"
}

variable "gpssa_vm_subnet_cidr" {
  type        = string
  description = "Subnet CIDR for the GPSSA-sim test VM"
  default     = "192.168.1.0/24"
}

variable "vm_admin_username" {
  type        = string
  default     = "azureuser"
}

variable "vm_ssh_public_key" {
  type        = string
  description = "Contents of your ~/.ssh/id_rsa.pub"
}

variable "ssh_source_ip" {
  type        = string
  description = "Your public IP (x.x.x.x/32) allowed to SSH into the test VM. Find it at https://ifconfig.me"
  default     = "*"
}
