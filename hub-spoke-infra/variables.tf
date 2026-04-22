variable "resource_group_name" {
  description = "Name of the main resource group"
  type        = string
  default     = "rg-hub-spoke-infra"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "uaenorth"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    project    = "hub-spoke-gpssa"
    managed_by = "terraform"
  }
}

# ── Hub VNet ────────────────────────────────
variable "hub_vnet_cidr" {
  description = "Address space for the Hub VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "hub_firewall_subnet_cidr" {
  description = "CIDR for AzureFirewallSubnet (must be /26 or larger)"
  type        = string
  default     = "10.0.0.0/26"
}

variable "hub_gateway_subnet_cidr" {
  description = "CIDR for GatewaySubnet"
  type        = string
  default     = "10.0.1.0/27"
}

# ── Spoke VNets ─────────────────────────────
variable "spokes" {
  description = "Map of spoke environments with their network CIDRs"
  type = map(object({
    vnet_cidr       = string
    aks_subnet_cidr = string
  }))
  default = {
    prod = {
      vnet_cidr       = "10.1.0.0/16"
      aks_subnet_cidr = "10.1.0.0/22"
    }
    stg = {
      vnet_cidr       = "10.2.0.0/16"
      aks_subnet_cidr = "10.2.0.0/22"
    }
    dev = {
      vnet_cidr       = "10.3.0.0/16"
      aks_subnet_cidr = "10.3.0.0/22"
    }
  }
}

# ── GPSSA (On-Premises) ─────────────────────
variable "gpssa_vpn_public_ip" {
  description = "Public IP address of the GPSSA on-premises VPN device"
  type        = string
}

variable "gpssa_prod_cidr" {
  description = "GPSSA PROD on-premises network CIDR"
  type        = string
  default     = "192.168.10.0/24"
}

variable "gpssa_stg_cidr" {
  description = "GPSSA STG on-premises network CIDR"
  type        = string
  default     = "192.168.20.0/24"
}

variable "gpssa_dev_cidr" {
  description = "GPSSA DEV on-premises network CIDR"
  type        = string
  default     = "192.168.30.0/24"
}

variable "vpn_shared_key" {
  description = "IPsec pre-shared key for VPN connections. Set via TF_VAR_vpn_shared_key env var."
  type        = string
  sensitive   = true
}

# ── AKS ─────────────────────────────────────
variable "kubernetes_version" {
  description = "Kubernetes version for all AKS clusters"
  type        = string
  default     = "1.29"
}

variable "aks_node_counts" {
  description = "Initial node count per environment"
  type        = map(number)
  default = {
    prod = 3
    stg  = 2
    dev  = 1
  }
}

variable "aks_vm_sizes" {
  description = "Node VM size per environment"
  type        = map(string)
  default = {
    prod = "Standard_D4s_v5"
    stg  = "Standard_D2s_v5"
    dev  = "Standard_B2s"
  }
}
