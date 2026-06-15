output "resource_group_network" {
  value       = azurerm_resource_group.network.name
  description = "Network spoke resource group"
}

output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "PRD spoke VNet ID"
}

output "vnet_name" {
  value       = azurerm_virtual_network.vnet.name
  description = "PRD spoke VNet name"
}

output "subnet_aks_sys_id" {
  value       = azurerm_subnet.aks_sys.id
  description = "snet-eip-prd-aks-sys ID (10.30.0.0/26)"
}

output "subnet_aks_devops_id" {
  value       = azurerm_subnet.aks_devops.id
  description = "snet-eip-prd-aks-devops ID (10.30.0.64/26)"
}

output "subnet_shared_id" {
  value       = azurerm_subnet.shared.id
  description = "snet-eip-prd-shared ID (10.30.0.128/26)"
}

output "subnet_resv_id" {
  value       = azurerm_subnet.resv.id
  description = "snet-eip-prd-resv ID (10.30.0.192/26)"
}

output "subnet_aks_app01_id" {
  value       = azurerm_subnet.aks_app01.id
  description = "snet-eip-prd-aks-app01 ID (10.30.1.0/24)"
}

output "storage_account_name" {
  value       = module.storage.storage_account_name
  description = "PRD storage account name"
}

output "storage_account_id" {
  value       = module.storage.storage_account_id
  description = "PRD storage account resource ID"
}

output "private_endpoint_storage_ip" {
  value       = azurerm_private_endpoint.storage.private_service_connection[0].private_ip_address
  description = "Private IP of pe-eip-storage-prd"
}

output "peering_prd_to_stg" {
  value       = azurerm_virtual_network_peering.prd_to_stg.id
  description = "Peering ID: prd → stg"
}

output "peering_prd_to_dev" {
  value       = azurerm_virtual_network_peering.prd_to_dev.id
  description = "Peering ID: prd → dev"
}

output "firewall_private_ip" {
  value       = data.azurerm_firewall.hub.ip_configuration[0].private_ip_address
  description = "Hub firewall private IP (next-hop for route table)"
}
