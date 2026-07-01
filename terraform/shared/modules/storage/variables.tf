variable "rg_name_override" {
  type        = string
  default     = null
  description = "Override the storage resource group name. Defaults to rg-storage-{prefix}-{environment}-{location}"
}

variable "storage_account_name_override" {
  type        = string
  default     = null
  description = "Override the storage account name. Defaults to {prefix}{environment}storage001"
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
  description = "The Azure Region"
}

variable "environment" {
  type        = string
  description = "The environment (dev, stg, prd, dr)"
}

variable "storage_account_tier" {
  type        = string
  description = "Storage account tier"
  default     = "Standard"
}

variable "storage_replication_type" {
  type        = string
  description = "Storage replication type"
  default     = "LRS"
}
