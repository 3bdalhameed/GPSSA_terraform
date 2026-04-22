variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "hub_vnet_cidr"       { type = string }
variable "firewall_subnet_cidr" { type = string }
variable "gateway_subnet_cidr" { type = string }
variable "tags"                { type = map(string) }
