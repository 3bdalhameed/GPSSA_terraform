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

variable "acr_sku" {
  type        = string
  description = "The SKU of the container registry"
  default     = "Standard"
}

variable "acr_admin_enabled" {
  type        = bool
  description = "Enable admin user for ACR"
  default     = true
}
