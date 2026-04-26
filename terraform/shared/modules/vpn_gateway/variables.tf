variable "prefix" {
  type        = string
  description = "Resource prefix"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to deploy the VPN Gateway into"
}

variable "subnet_id" {
  type        = string
  description = "ID of GatewaySubnet (must be named exactly 'GatewaySubnet', /27 minimum)"
}

variable "sku" {
  type        = string
  description = "VPN Gateway SKU — VpnGw1 is sufficient for testing"
  default     = "VpnGw1"
}

variable "tags" {
  type    = map(string)
  default = {}
}
