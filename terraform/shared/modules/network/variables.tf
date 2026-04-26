variable "prefix" {
  type        = string
  description = "The prefix which should be used for all resources"
}

variable "project" {
  type        = string
  description = "The project which should be used for all resources"
}

variable "location" {
  type        = string
  description = "The Azure Region in which all resources should be created"
}

variable "environment" {
  type        = string
  description = "The environment (dev, stg, prd, dr)"
}

variable "vnet_cidr" {
  type        = string
  description = "The CIDR block for the virtual network"
}
