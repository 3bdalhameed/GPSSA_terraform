variable "prefix" {
  type        = string
  description = "Resource prefix"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "vnet_cidr" {
  type        = string
  description = "Virtual network CIDR"
}

variable "aks_cluster_name" {
  type        = string
  description = "AKS cluster name"
}

variable "aks_dns_prefix" {
  type        = string
  description = "AKS DNS prefix"
}

variable "aks_node_count" {
  type        = number
  description = "Number of AKS nodes"
}

variable "aks_vm_size" {
  type        = string
  description = "AKS VM size"
}

variable "kubernetes_version" {
  type        = string
  default     = null
  description = "Kubernetes version"
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

variable "acr_sku" {
  type        = string
  description = "ACR SKU"
}

variable "acr_admin_enabled" {
  type        = bool
  description = "Enable ACR admin"
}

variable "storage_account_tier" {
  type        = string
  description = "Storage account tier"
}

variable "storage_replication_type" {
  type        = string
  description = "Storage replication type"
}

variable "enable_gateway_transit" {
  type        = bool
  description = "Set to true after the Hub VPN Gateway is provisioned to allow spoke traffic to flow through it"
  default     = false
}
