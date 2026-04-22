resource "azurerm_resource_group" "acr" {
  name     = "rg-acr-${var.prefix}-${var.environment}-${var.location}"
  location = var.location
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "random_string" "acr_suffix" {
  length  = 4
  special = false
  lower   = true
  numeric = true
}

resource "azurerm_container_registry" "acr" {
  name                = lower("${var.prefix}${var.environment}acr${random_string.acr_suffix.result}")
  resource_group_name = azurerm_resource_group.acr.name
  location            = azurerm_resource_group.acr.location
  sku                 = var.acr_sku
  admin_enabled       = var.acr_admin_enabled

  tags = {
    environment = var.environment
    project     = var.project
  }
}
