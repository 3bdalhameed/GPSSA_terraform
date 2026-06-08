variable "rg_name_override" {
  type        = string
  default     = null
  description = "Override the AKS resource group name. Defaults to rg-aks-{prefix}-{environment}-{location}"
}

variable "prefix" {
  type        = string
  description = "The prefix which should be used for all resources"
}

variable "project" {
  type        = string
  description = "The project name"
}

variable "location" {
  type        = string
  description = "The Azure Region in which resources should be created"
}

variable "environment" {
  type        = string
  description = "The environment (dev, stg, prd, dr)"
}

variable "aks_cluster_name" {
  type        = string
  description = "The name of the AKS cluster"
}

variable "aks_dns_prefix" {
  type        = string
  description = "DNS prefix for the AKS cluster"
}

variable "aks_node_count" {
  type        = number
  description = "Number of nodes in the AKS default node pool"
}

variable "aks_vm_size" {
  type        = string
  description = "VM size for the AKS nodes"
}

variable "kubernetes_version" {
  type        = string
  default     = null
  description = "Kubernetes version (null for latest)"
}

variable "app_node_pool_name" {
  type        = string
  description = "Name of the app node pool"
  default     = "app"
}

variable "app_node_count" {
  type        = number
  description = "Number of nodes in the app node pool"
}

variable "app_vm_size" {
  type        = string
  description = "VM size for the app node pool"
}

variable "subnet_aks_system_id" {
  type        = string
  description = "Subnet ID from network module for system node pool"
}

variable "subnet_aks_app_id" {
  type        = string
  description = "Subnet ID from network module for app node pool"
}

variable "enable_key_vault_secrets_provider" {
  type        = bool
  default     = false
  description = "Enable the Key Vault Secrets Provider addon (required for CSI secret store)"
}
