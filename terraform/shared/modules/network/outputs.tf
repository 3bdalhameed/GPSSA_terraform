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

output "subnet_aks_system_id" {
  value       = azurerm_subnet.subnet2.id
  description = "ID of the AKS system subnet"
}

output "subnet_aks_app_id" {
  value       = azurerm_subnet.subnet3.id
  description = "ID of the AKS app subnet"
}
