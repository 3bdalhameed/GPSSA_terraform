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
  description = "Resource group to deploy the Application Gateway into"
}

variable "subnet_id" {
  type        = string
  description = "ID of the ApplicationGatewaySubnet (must be /24 or larger)"
}

variable "sku_name" {
  type        = string
  description = "Application Gateway SKU name: Standard_v2 or WAF_v2"
  default     = "Standard_v2"
}

variable "sku_tier" {
  type        = string
  description = "Application Gateway SKU tier: Standard_v2 or WAF_v2"
  default     = "Standard_v2"
}

variable "capacity" {
  type        = number
  description = "Number of Application Gateway instances (min 1)"
  default     = 2
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}

variable "backends" {
  type = map(object({
    ip_addresses = list(string)
    fqdns        = list(string)
    hostname     = string
    priority     = number
  }))
  description = <<-EOT
    Backend pool config keyed by environment name (e.g. prod, stg, dev).
    ip_addresses / fqdns   — AKS service IPs or FQDNs (fill in after spokes are provisioned).
    hostname               — Host header used to route to this pool (host-based listener).
    priority               — Unique routing-rule priority (100, 200, 300 …).
  EOT
  default = {
    prod = {
      ip_addresses = []
      fqdns        = []
      hostname     = "prod.internal"
      priority     = 100
    }
    stg = {
      ip_addresses = []
      fqdns        = []
      hostname     = "stg.internal"
      priority     = 200
    }
    dev = {
      ip_addresses = []
      fqdns        = []
      hostname     = "dev.internal"
      priority     = 300
    }
  }
}
