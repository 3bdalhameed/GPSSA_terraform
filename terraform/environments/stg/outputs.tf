output "resource_group_network" {
  value       = azurerm_resource_group.network.name
  description = "Network spoke resource group"
}

output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "STG spoke VNet ID"
}

output "vnet_name" {
  value       = azurerm_virtual_network.vnet.name
  description = "STG spoke VNet name"
}

output "subnet_aks_sys_id" {
  value       = azurerm_subnet.aks_sys.id
  description = "snet-eip-stg-aks-sys ID (10.15.250.0/26)"
}

output "subnet_aks_app01_id" {
  value       = azurerm_subnet.aks_app01.id
  description = "snet-eip-stg-aks-app01 ID (10.15.250.64/26)"
}

output "subnet_aks_app02_id" {
  value       = azurerm_subnet.aks_app02.id
  description = "snet-eip-stg-aks-app02 ID (10.15.251.0/24)"
}

output "subnet_shared_id" {
  value       = azurerm_subnet.shared.id
  description = "Shared/private-endpoint subnet ID"
}

output "subnet_resv_id" {
  value       = azurerm_subnet.resv.id
  description = "Reserved subnet ID"
}

output "storage_account_name" {
  value       = module.storage.storage_account_name
  description = "STG storage account name"
}

output "storage_account_id" {
  value       = module.storage.storage_account_id
  description = "STG storage account resource ID"
}

output "private_endpoint_storage_ip" {
  value       = azurerm_private_endpoint.storage.private_service_connection[0].private_ip_address
  description = "Private IP of pe-eip-storage-stg"
}

output "firewall_private_ip" {
  value       = data.azurerm_firewall.hub.ip_configuration[0].private_ip_address
  description = "Hub firewall private IP (next-hop for route table)"
}
