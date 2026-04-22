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
  description = "Environment (dev, stg, prd, dr)"
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
  description = "ID of the AzureFirewallSubnet"
}

variable "sku_tier" {
  type        = string
  default     = "Standard"
  description = "Firewall SKU tier (Basic, Standard, Premium)"
}

variable "threat_intel_mode" {
  type        = string
  default     = "Alert"
  description = "Threat intel mode (Off, Alert, Deny)"
}
