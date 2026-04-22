output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Name of the network resource group"
}

output "resource_group_id" {
  value       = azurerm_resource_group.rg.id
  description = "ID of the network resource group"
}

output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "ID of the virtual network"
}

output "vnet_name" {
  value       = azurerm_virtual_network.vnet.name
  description = "Name of the virtual network"
}

output "subnet_web_id" {
  value       = azurerm_subnet.subnet1.id
  description = "ID of the web subnet"
}

output "subnet_aks_system_id" {
  value       = azurerm_subnet.subnet2.id
  description = "ID of the AKS system subnet"
}

output "subnet_aks_app_id" {
  value       = azurerm_subnet.subnet3.id
  description = "ID of the AKS app subnet"
}

output "subnet_db_id" {
  value       = azurerm_subnet.subnet4.id
  description = "ID of the DB subnet"
}

output "route_table_id" {
  value       = try(azurerm_route_table.spoke[0].id, null)
  description = "ID of the spoke route table (null if firewall routing disabled)"
}

output "subnet_firewall_id" {
  value       = azurerm_subnet.firewall.id
  description = "ID of the AzureFirewallSubnet"
}
