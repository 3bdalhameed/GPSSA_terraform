variable "prefix" {
  type        = string
  description = "Resource prefix"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "hub_vnet_cidr" {
  type        = string
  description = "CIDR block for the hub VNet (e.g. 10.0.0.0/16)"
}

variable "firewall_subnet_cidr" {
  type        = string
  description = "CIDR for AzureFirewallSubnet — must be /26 or larger within hub_vnet_cidr"
}

variable "firewall_sku_tier" {
  type        = string
  description = "Azure Firewall SKU tier: Standard or Premium"
  default     = "Standard"
}
