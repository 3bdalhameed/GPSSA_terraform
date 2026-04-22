output "vnet_ids" {
  value = { for k, v in azurerm_virtual_network.spoke : k => v.id }
}

output "aks_subnet_ids" {
  value = { for k, v in azurerm_subnet.aks : k => v.id }
}
