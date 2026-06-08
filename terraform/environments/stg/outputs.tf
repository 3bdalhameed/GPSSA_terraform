output "resource_group_network" {
  value       = azurerm_resource_group.network.name
  description = "Network spoke resource group"
}

output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "Spoke VNet ID"
}

output "vnet_name" {
  value       = azurerm_virtual_network.vnet.name
  description = "Spoke VNet name"
}

output "subnet_aks_sys_id" {
  value       = azurerm_subnet.aks_sys.id
  description = "AKS system node subnet ID"
}

output "subnet_aks_app_id" {
  value       = azurerm_subnet.aks_app.id
  description = "AKS app node subnet ID"
}

output "subnet_shared_id" {
  value       = azurerm_subnet.shared.id
  description = "Shared/private-endpoint subnet ID"
}

output "aks_cluster_name" {
  value       = module.aks.aks_cluster_name
  description = "AKS cluster name"
}

output "kubelet_identity_object_id" {
  value       = module.aks.kubelet_identity_object_id
  description = "Object ID of aks-eip-stg-agentpool managed identity"
}

output "kubelet_identity_client_id" {
  value       = module.aks.kubelet_identity_client_id
  description = "Client ID of aks-eip-stg-agentpool (use for workload identity federation)"
}

output "key_vault_secrets_provider_object_id" {
  value       = module.aks.key_vault_secrets_provider_object_id
  description = "Object ID of azurekeyvaultsecretsprovider-aks-eip-stg identity"
}

output "acr_login_server" {
  value       = data.azurerm_container_registry.shared.login_server
  description = "Shared nonprod ACR login server"
}

output "storage_account_name" {
  value       = module.storage.storage_account_name
  description = "stg storage account name"
}

output "private_endpoint_acr_ip" {
  value       = azurerm_private_endpoint.acr.private_service_connection[0].private_ip_address
  description = "Private IP of pe-eip-acr-stg"
}

output "private_endpoint_storage_ip" {
  value       = azurerm_private_endpoint.storage.private_service_connection[0].private_ip_address
  description = "Private IP of pe-eip-storage-stg"
}

output "firewall_private_ip" {
  value       = data.terraform_remote_state.shared.outputs.firewall_private_ip
  description = "Hub firewall private IP (next-hop for route table)"
}
