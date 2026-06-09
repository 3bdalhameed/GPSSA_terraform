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
  description = "Environment name (stg)"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "vnet_cidr" {
  type        = string
  description = "Spoke VNet CIDR — must cover all subnet ranges (10.15.250.0/23)"
}

variable "subnet_aks_sys_cidr" {
  type        = string
  description = "CIDR for snet-eip-stg-aks-sys"
}

variable "subnet_aks_app01_cidr" {
  type        = string
  description = "CIDR for snet-eip-stg-aks-app01"
}

variable "subnet_shared_cidr" {
  type        = string
  description = "CIDR for snet-eip-stg-shared (private endpoints)"
}

variable "subnet_resv_cidr" {
  type        = string
  description = "CIDR for snet-eip-stg-resv (reserved)"
}

variable "subnet_aks_app02_cidr" {
  type        = string
  description = "CIDR for snet-eip-stg-aks-app02"
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

# ── Shared existing resources ─────────────────────────────────────────────────

variable "dns_zone_resource_group" {
  type        = string
  description = "RG that holds the existing private DNS zones (rg-eip-shared-network-hub)"
}

