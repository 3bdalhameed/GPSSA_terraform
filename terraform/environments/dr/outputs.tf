# ── DR Hub ────────────────────────────────────────────────────────────────────

output "dr_hub_resource_group" {
  value       = azurerm_resource_group.dr_hub.name
  description = "DR hub resource group"
}

output "dr_hub_vnet_id" {
  value       = azurerm_virtual_network.dr_hub_vnet.id
  description = "DR hub VNet ID"
}

output "dr_firewall_private_ip" {
  value       = azurerm_firewall.dr.ip_configuration[0].private_ip_address
  description = "DR firewall private IP (next-hop for DR spoke route table)"
}

output "dr_firewall_public_ip" {
  value       = azurerm_public_ip.dr_firewall.ip_address
  description = "DR firewall public IP"
}

output "dr_vpn_gateway_public_ip" {
  value       = azurerm_public_ip.dr_vpn_gateway.ip_address
  description = "DR VPN gateway public IP"
}

# ── DR Spoke ──────────────────────────────────────────────────────────────────

output "resource_group_network" {
  value       = azurerm_resource_group.network.name
  description = "DR spoke network resource group"
}

output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "DR spoke VNet ID"
}

output "vnet_name" {
  value       = azurerm_virtual_network.vnet.name
  description = "DR spoke VNet name"
}

output "subnet_aks_sys_id" {
  value       = azurerm_subnet.aks_sys.id
  description = "snet-eip-dr-aks-sys ID"
}

output "subnet_aks_devops_id" {
  value       = azurerm_subnet.aks_devops.id
  description = "snet-eip-dr-aks-devops ID"
}

output "subnet_shared_id" {
  value       = azurerm_subnet.shared.id
  description = "snet-eip-dr-shared ID"
}

output "subnet_resv_id" {
  value       = azurerm_subnet.resv.id
  description = "snet-eip-dr-resv ID"
}

output "subnet_aks_app01_id" {
  value       = azurerm_subnet.aks_app01.id
  description = "snet-eip-dr-aks-app01 ID"
}

# ── Storage ───────────────────────────────────────────────────────────────────

output "storage_account_name" {
  value       = module.storage.storage_account_name
  description = "DR storage account name"
}

output "storage_account_id" {
  value       = module.storage.storage_account_id
  description = "DR storage account resource ID"
}

output "private_endpoint_storage_ip" {
  value       = azurerm_private_endpoint.storage.private_service_connection[0].private_ip_address
  description = "Private IP of pe-eip-storage-dr"
}
