locals {
  rg_name = coalesce(var.rg_name_override, "rg-storage-${var.prefix}-${var.environment}-${var.location}")
}

resource "azurerm_resource_group" "storage" {
  name     = local.rg_name
  location = var.location
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_storage_account" "storage" {
  name                     = replace("${var.prefix}${var.environment}storage001", "-", "")
  resource_group_name      = azurerm_resource_group.storage.name
  location                 = azurerm_resource_group.storage.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type

  tags = {
    environment = var.environment
    project     = var.project
  }
}
