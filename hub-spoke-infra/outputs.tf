output "resource_group_name" {
  description = "Name of the main resource group"
  value       = azurerm_resource_group.main.name
}

output "hub_vnet_id" {
  description = "Hub VNet resource ID"
  value       = module.hub.vnet_id
}

output "firewall_private_ip" {
  description = "Azure Firewall private IP (referenced by route tables)"
  value       = module.hub.firewall_private_ip
}

output "firewall_public_ip" {
  description = "Azure Firewall public IP"
  value       = module.hub.firewall_public_ip
}

output "vpn_gateway_public_ip" {
  description = "VPN Gateway public IP — share this with the GPSSA team for tunnel configuration"
  value       = module.vpn.gateway_public_ip
}

output "spoke_vnet_ids" {
  description = "Spoke VNet IDs per environment"
  value       = module.spokes.vnet_ids
}

output "aks_cluster_names" {
  description = "AKS cluster names per environment"
  value       = module.aks.cluster_names
}

output "aks_kube_configs" {
  description = "Raw kubeconfig per AKS cluster (sensitive)"
  sensitive   = true
  value       = module.aks.kube_configs
}
