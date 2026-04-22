variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "gateway_subnet_id"   { type = string }
variable "vpn_shared_key"      { type = string; sensitive = true }
variable "gpssa_vpn_public_ip" { type = string }
variable "gpssa_prod_cidr"     { type = string }
variable "gpssa_stg_cidr"      { type = string }
variable "gpssa_dev_cidr"      { type = string }
variable "tags"                { type = map(string) }
