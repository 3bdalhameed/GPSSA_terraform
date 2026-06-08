output "resource_group_name" {
  value       = azurerm_resource_group.aks.name
  description = "Name of the AKS resource group"
}

output "aks_cluster_id" {
  value       = azurerm_kubernetes_cluster.aks.id
  description = "ID of the AKS cluster"
}

output "aks_cluster_name" {
  value       = azurerm_kubernetes_cluster.aks.name
  description = "Name of the AKS cluster"
}

output "kube_config" {
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
  description = "Kubernetes config for kubectl"
}

output "aks_identity_principal_id" {
  value       = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  description = "Principal ID of the AKS cluster system-assigned identity"
}

output "kubelet_identity_object_id" {
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  description = "Object ID of the AKS kubelet (node/agentpool) managed identity"
}

output "kubelet_identity_client_id" {
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].client_id
  description = "Client ID of the AKS kubelet managed identity (used for workload identity federation)"
}

output "key_vault_secrets_provider_object_id" {
  value       = try(azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].object_id, null)
  description = "Object ID of the azurekeyvaultsecretsprovider addon managed identity"
}
