output "resource_group_network" {
  value       = module.network.resource_group_name
  description = "Network resource group name"
}

output "vnet_id" {
  value       = module.network.vnet_id
  description = "Virtual network ID"
}

output "aks_cluster_name" {
  value       = module.aks.aks_cluster_name
  description = "AKS cluster name"
}

output "acr_login_server" {
  value       = module.acr.acr_login_server
  description = "ACR login server"
}

output "storage_account_name" {
  value       = module.storage.storage_account_name
  description = "Storage account name"
}

output "firewall_private_ip" {
  value       = try(module.firewall[0].firewall_private_ip, null)
  description = "Private IP of the deployed firewall (null if not deployed)"
}

output "firewall_public_ip" {
  value       = try(module.firewall[0].firewall_public_ip, null)
  description = "Public IP of the deployed firewall (null if not deployed)"
}
