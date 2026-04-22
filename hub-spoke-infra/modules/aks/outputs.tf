output "cluster_names" {
  value = { for k, v in azurerm_kubernetes_cluster.spoke : k => v.name }
}

output "cluster_ids" {
  value = { for k, v in azurerm_kubernetes_cluster.spoke : k => v.id }
}

output "kube_configs" {
  sensitive = true
  value     = { for k, v in azurerm_kubernetes_cluster.spoke : k => v.kube_config_raw }
}
