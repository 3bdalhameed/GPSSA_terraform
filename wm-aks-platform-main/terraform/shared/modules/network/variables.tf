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

# ── Hub integration (optional) ───────────────
variable "enable_hub_peering" {
  type        = bool
  description = "Peer this spoke VNet with the hub VNet"
  default     = false
}

variable "hub_vnet_id" {
  type        = string
  description = "Resource ID of the hub VNet (required when enable_hub_peering = true)"
  default     = null
}

variable "hub_vnet_name" {
  type        = string
  description = "Name of the hub VNet (required when enable_hub_peering = true)"
  default     = null
}

variable "hub_resource_group_name" {
  type        = string
  description = "Resource group of the hub VNet (required when enable_hub_peering = true)"
  default     = null
}

variable "use_remote_gateways" {
  type        = bool
  description = "Use the hub's VPN/ER gateway for this spoke"
  default     = false
}

# ── Firewall egress (optional) ───────────────
variable "enable_firewall_routing" {
  type        = bool
  description = "Create a route table that forces 0.0.0.0/0 to the hub firewall"
  default     = false
}

variable "firewall_private_ip" {
  type        = string
  description = "Private IP of the hub Azure Firewall (required when enable_firewall_routing = true)"
  default     = null
}
