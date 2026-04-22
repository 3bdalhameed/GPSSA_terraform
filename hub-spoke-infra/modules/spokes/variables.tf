variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "hub_vnet_id"         { type = string }
variable "firewall_private_ip" { type = string }
variable "vpn_gateway_id"      { type = string }
variable "tags"                { type = map(string) }

variable "spokes" {
  type = map(object({
    vnet_cidr       = string
    aks_subnet_cidr = string
  }))
}
