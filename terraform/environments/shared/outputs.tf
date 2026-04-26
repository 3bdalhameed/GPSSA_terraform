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
