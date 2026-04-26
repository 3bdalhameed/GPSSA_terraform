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

variable "vnet_cidr" {
  type        = string
  description = "CIDR for the shared hub VNet (must not overlap with any spoke)"
}

variable "firewall_sku_tier" {
  type        = string
  default     = "Standard"
  description = "Firewall SKU tier (Basic, Standard, Premium)"
}
