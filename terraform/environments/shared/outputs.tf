output "hub_vnet_id" {
  value       = azurerm_virtual_network.hub.id
  description = "ID of the hub VNet"
}

output "hub_vnet_name" {
  value       = azurerm_virtual_network.hub.name
  description = "Name of the hub VNet"
}

output "hub_resource_group_name" {
  value       = azurerm_resource_group.hub.name
  description = "Name of the hub resource group"
}

output "firewall_private_ip" {
  value       = module.firewall.firewall_private_ip
  description = "Private IP of the Azure Firewall — used as next-hop in spoke route tables"
}

output "firewall_public_ip" {
  value       = module.firewall.firewall_public_ip
  description = "Public IP of the Azure Firewall"
}

output "hub_vnet_cidr" {
  value       = var.hub_vnet_cidr
  description = "CIDR of the hub VNet — used by GPSSA-sim LNG to know Azure address space"
}

output "vpn_gateway_id" {
  value       = module.vpn_gateway.gateway_id
  description = "Resource ID of the Hub VPN Gateway"
}

output "vpn_gateway_name" {
  value       = module.vpn_gateway.gateway_name
  description = "Name of the Hub VPN Gateway"
}

output "vpn_gateway_public_ip" {
  value       = module.vpn_gateway.gateway_public_ip
  description = "Public IP of the Hub VPN Gateway — used by GPSSA-sim as peer address"
}

# App Gateway outputs will be added back once the module is re-enabled
