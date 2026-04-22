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

# ── Hub integration (optional) ───────────────
variable "enable_hub_peering" {
  type        = bool
  default     = false
  description = "Peer spoke VNet with the hub VNet"
}

variable "hub_vnet_id" {
  type        = string
  default     = null
  description = "Resource ID of the hub VNet"
}

variable "hub_vnet_name" {
  type        = string
  default     = null
  description = "Name of the hub VNet"
}

variable "hub_resource_group_name" {
  type        = string
  default     = null
  description = "Resource group of the hub VNet"
}

variable "use_remote_gateways" {
  type        = bool
  default     = false
  description = "Use hub VPN/ER gateway from this spoke"
}

variable "enable_firewall_routing" {
  type        = bool
  default     = false
  description = "Force egress through the hub Azure Firewall"
}

variable "firewall_private_ip" {
  type        = string
  default     = null
  description = "Private IP of the hub Azure Firewall (ignored when deploy_firewall = true)"
}

variable "deploy_firewall" {
  type        = bool
  default     = false
  description = "Deploy a local Azure Firewall inside this spoke's VNet"
}

variable "firewall_sku_tier" {
  type        = string
  default     = "Standard"
  description = "Firewall SKU tier (Basic, Standard, Premium)"
}
