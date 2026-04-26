output "firewall_private_ip" {
  value       = module.firewall.firewall_private_ip
  description = "Private IP of the shared firewall — use as firewall_private_ip in each environment"
}

output "firewall_public_ip" {
  value       = module.firewall.firewall_public_ip
  description = "Public IP of the shared firewall"
}

output "vnet_id" {
  value       = azurerm_virtual_network.shared.id
  description = "Resource ID of the shared hub VNet — use as hub_vnet_id in each environment"
}

output "vnet_name" {
  value       = azurerm_virtual_network.shared.name
  description = "Name of the shared hub VNet — use as hub_vnet_name in each environment"
}

output "resource_group_name" {
  value       = azurerm_resource_group.shared.name
  description = "Shared resource group name — use as hub_resource_group_name in each environment"
}
