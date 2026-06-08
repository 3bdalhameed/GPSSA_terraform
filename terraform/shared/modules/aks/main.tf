locals {
  rg_name = coalesce(var.rg_name_override, "rg-aks-${var.prefix}-${var.environment}-${var.location}")
}

resource "azurerm_resource_group" "aks" {
  name     = local.rg_name
  location = var.location
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = var.aks_dns_prefix
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name           = "system"
    node_count     = var.aks_node_count
    vm_size        = var.aks_vm_size
    vnet_subnet_id = var.subnet_aks_system_id

    upgrade_settings {
      max_surge = "10%"
    }
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "10.0.0.0/16"
    dns_service_ip    = "10.0.0.10"
  }

  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  role_based_access_control_enabled = true

  identity {
    type = "SystemAssigned"
  }

  dynamic "key_vault_secrets_provider" {
    for_each = var.enable_key_vault_secrets_provider ? [1] : []
    content {
      secret_rotation_enabled  = true
      secret_rotation_interval = "2m"
    }
  }

  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "app" {
  name                  = var.app_node_pool_name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  node_count            = var.app_node_count
  vm_size               = var.app_vm_size
  vnet_subnet_id        = var.subnet_aks_app_id

  tags = {
    environment = var.environment
    project     = var.project
    pool_type   = "application"
  }
}
