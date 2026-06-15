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
  description = "Environment name (prd)"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "vnet_cidr" {
  type        = string
  description = "Spoke VNet CIDR — must cover all subnet ranges (10.30.0.0/23)"
}

variable "subnet_aks_sys_cidr" {
  type        = string
  description = "CIDR for snet-eip-prd-aks-sys"
}

variable "subnet_aks_devops_cidr" {
  type        = string
  description = "CIDR for snet-eip-prd-aks-devops"
}

variable "subnet_shared_cidr" {
  type        = string
  description = "CIDR for snet-eip-prd-shared (private endpoints)"
}

variable "subnet_resv_cidr" {
  type        = string
  description = "CIDR for snet-eip-prd-resv (reserved)"
}

variable "subnet_aks_app01_cidr" {
  type        = string
  description = "CIDR for snet-eip-prd-aks-app01"
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

# ── STG references (for cross-environment peering) ────────────────────────────

variable "stg_resource_group_name" {
  type        = string
  description = "STG network resource group (rg-eip-stg-network-spoke)"
}

variable "stg_vnet_name" {
  type        = string
  description = "STG VNet name (eip-stg-vnet)"
}

# ── DEV references (for cross-environment peering) ────────────────────────────

variable "dev_resource_group_name" {
  type        = string
  description = "DEV network resource group (rg-eip-dev-network-spoke)"
}

variable "dev_vnet_name" {
  type        = string
  description = "DEV VNet name (eip-dev-vnet)"
}

# ── Hub references (read directly from Azure — no remote state needed) ─────────

variable "hub_resource_group_name" {
  type        = string
  description = "Hub network resource group (rg-eip-shared-network-hub)"
}

variable "hub_vnet_name" {
  type        = string
  description = "Hub VNet name (eip-hub-vnet)"
}

variable "hub_firewall_name" {
  type        = string
  description = "Hub firewall name (fw-eip-hub)"
}
