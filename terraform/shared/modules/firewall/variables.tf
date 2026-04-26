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

variable "resource_group_name" {
  type        = string
  description = "Resource group to deploy the firewall into"
}

variable "firewall_subnet_id" {
  type        = string
  description = "ID of the AzureFirewallSubnet (must be /26 or larger)"
}

variable "sku_tier" {
  type        = string
  description = "Azure Firewall SKU tier: Standard or Premium"
  default     = "Standard"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}
