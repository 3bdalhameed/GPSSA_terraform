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
  description = "Spoke VNet CIDR — must not overlap with hub or dev (e.g. 10.20.0.0/16)"
}

# ── AKS ───────────────────────────────────────────────────────────────────────

variable "aks_cluster_name" {
  type        = string
  description = "AKS cluster name (e.g. aks-eip-stg)"
}

variable "aks_dns_prefix" {
  type        = string
  description = "AKS DNS prefix"
}

variable "aks_node_count" {
  type        = number
  description = "Number of AKS system nodes"
}

variable "aks_vm_size" {
  type        = string
  description = "AKS system node VM size"
}

variable "kubernetes_version" {
  type        = string
  default     = null
  description = "Kubernetes version (null = latest)"
}

variable "app_node_pool_name" {
  type        = string
  description = "App node pool name"
}

variable "app_node_count" {
  type        = number
  description = "Number of app nodes"
}

variable "app_vm_size" {
  type        = string
  description = "VM size for app nodes"
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

variable "acr_name" {
  type        = string
  description = "Name of the shared nonprod ACR (e.g. acreipnonprd5shr)"
}

variable "acr_resource_group_name" {
  type        = string
  description = "RG of the shared nonprod ACR — also where pe-eip-acr-stg will be created (e.g. rg-eip-nonprod-acr)"
}

variable "dns_zone_resource_group" {
  type        = string
  description = "RG that holds the existing private DNS zones (rg-eip-shared-network-hub)"
}

# ── Optional: populate once database/KV resources are created ─────────────────

variable "postgres_server_id" {
  type        = string
  default     = null
  description = "Resource ID of stg PostgreSQL Server — activates pe-eip-postgres-stg"
}

variable "postgres_resource_group_name" {
  type        = string
  default     = null
  description = "RG where pe-eip-postgres-stg will be created (e.g. rg-eip-nonprod-sql)"
}

variable "sql_server_id" {
  type        = string
  default     = null
  description = "Resource ID of the nonprod SQL Server — activates pe-eip-sql-stg"
}

variable "sql_resource_group_name" {
  type        = string
  default     = null
  description = "RG where pe-eip-sql-stg will be created (e.g. rg-eip-nonprod-sql)"
}

variable "key_vault_id" {
  type        = string
  default     = null
  description = "Resource ID of the Key Vault — activates Key Vault Secrets Officer role for CSI driver (e.g. kveipdev01 in rg-eip-nonprod-kv)"
}
