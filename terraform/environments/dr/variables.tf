variable "prefix" {
  type        = string
  description = "Resource prefix (eip)"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name (dr)"
}

variable "dr_location" {
  type        = string
  description = "Azure region for DR (uaecentral)"
}

# ── DR Hub Network ────────────────────────────────────────────────────────────

variable "dr_hub_vnet_cidr" {
  type        = string
  description = "DR hub VNet CIDR (e.g. 10.1.0.0/16)"
}

variable "dr_firewall_subnet_cidr" {
  type        = string
  description = "CIDR for AzureFirewallSubnet in DR hub (/26 minimum)"
}

variable "dr_gateway_subnet_cidr" {
  type        = string
  description = "CIDR for GatewaySubnet in DR hub (/27 minimum)"
}

variable "firewall_sku_tier" {
  type        = string
  description = "Azure Firewall SKU tier (Standard or Premium)"
  default     = "Standard"
}

variable "vpn_gateway_sku" {
  type        = string
  description = "VPN Gateway SKU"
  default     = "VpnGw1"
}

# ── DR Spoke Network ──────────────────────────────────────────────────────────

variable "vnet_cidr" {
  type        = string
  description = "DR spoke VNet CIDR (e.g. 10.31.0.0/23)"
}

variable "subnet_aks_sys_cidr" {
  type        = string
  description = "CIDR for snet-eip-dr-aks-sys"
}

variable "subnet_aks_devops_cidr" {
  type        = string
  description = "CIDR for snet-eip-dr-aks-devops"
}

variable "subnet_shared_cidr" {
  type        = string
  description = "CIDR for snet-eip-dr-shared (private endpoints)"
}

variable "subnet_resv_cidr" {
  type        = string
  description = "CIDR for snet-eip-dr-resv (reserved)"
}

variable "subnet_aks_app01_cidr" {
  type        = string
  description = "CIDR for snet-eip-dr-aks-app01"
}

# ── Storage ───────────────────────────────────────────────────────────────────

variable "storage_account_tier" {
  type        = string
  description = "Storage account tier (Standard/Premium)"
}

variable "storage_replication_type" {
  type        = string
  description = "Storage replication type (LRS/GRS/GZRS)"
}

# ── Primary Hub references ────────────────────────────────────────────────────

variable "primary_hub_resource_group_name" {
  type        = string
  description = "Primary hub resource group (rg-eip-shared-network-hub)"
}

variable "primary_hub_vnet_name" {
  type        = string
  description = "Primary hub VNet name (eip-hub-vnet)"
}
