output "resource_group_name" {
  value       = azurerm_resource_group.storage.name
  description = "Name of the storage resource group"
}

output "storage_account_id" {
  value       = azurerm_storage_account.storage.id
  description = "ID of the storage account"
}

output "storage_account_name" {
  value       = azurerm_storage_account.storage.name
  description = "Name of the storage account"
}
