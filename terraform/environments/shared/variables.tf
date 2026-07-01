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

variable "hub_vnet_cidr" {
  type        = string
  description = "CIDR block for the hub VNet (e.g. 10.0.0.0/16)"
}

# ── Name overrides (set to actual Azure names when they differ from the generated pattern) ──

variable "hub_rg_name_override" {
  type        = string
  default     = null
  description = "Override hub resource group name"
}

variable "hub_vnet_name_override" {
  type        = string
  default     = null
  description = "Override hub VNet name"
}

variable "hub_firewall_name_override" {
  type        = string
  default     = null
  description = "Override hub firewall name"
}

variable "hub_vpngw_name_override" {
  type        = string
  default     = null
  description = "Override hub VPN gateway name"
}

variable "firewall_subnet_cidr" {
  type        = string
  description = "CIDR for AzureFirewallSubnet — must be /26 or larger within hub_vnet_cidr"
}

variable "firewall_sku_tier" {
  type        = string
  description = "Azure Firewall SKU tier: Standard or Premium"
  default     = "Standard"
}

# ── VPN Gateway ───────────────────────────────────────────────────────────────

variable "gateway_subnet_cidr" {
  type        = string
  description = "CIDR for GatewaySubnet — must be /27 or larger within hub_vnet_cidr"
}

variable "vpn_gateway_sku" {
  type        = string
  description = "VPN Gateway SKU"
  default     = "VpnGw1"
}

# ── Application Gateway ────────────────────────────────────────────────────────

variable "app_gateway_subnet_cidr" {
  type        = string
  description = "CIDR for ApplicationGatewaySubnet — must be /24 or larger within hub_vnet_cidr"
}

variable "app_gateway_sku_name" {
  type        = string
  description = "Application Gateway SKU name: Standard_v2 or WAF_v2"
  default     = "Standard_v2"
}

variable "app_gateway_sku_tier" {
  type        = string
  description = "Application Gateway SKU tier: Standard_v2 or WAF_v2"
  default     = "Standard_v2"
}

variable "app_gateway_capacity" {
  type        = number
  description = "Number of Application Gateway instances"
  default     = 2
}

variable "app_gateway_backends" {
  type = map(object({
    ip_addresses = list(string)
    fqdns        = list(string)
    hostname     = string
    priority     = number
  }))
  description = "Backend pool config keyed by environment name. Fill in ip_addresses/fqdns after spoke AKS services are provisioned."
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
