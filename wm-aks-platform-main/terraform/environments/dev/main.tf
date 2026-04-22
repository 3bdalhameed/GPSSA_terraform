terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "network" {
  source      = "../../shared/modules/network"
  prefix      = var.prefix
  project     = var.project
  environment = var.environment
  location    = var.location
  vnet_cidr   = var.vnet_cidr
}

module "aks" {
  source          = "../../shared/modules/aks"
  prefix          = var.prefix
  project         = var.project
  environment     = var.environment
  location        = var.location
  aks_cluster_name = var.aks_cluster_name
  aks_dns_prefix  = var.aks_dns_prefix
  aks_node_count  = var.aks_node_count
  aks_vm_size     = var.aks_vm_size
  kubernetes_version = var.kubernetes_version
  app_node_pool_name = var.app_node_pool_name
  app_node_count  = var.app_node_count
  app_vm_size     = var.app_vm_size
  
  # Use network module subnet outputs
  subnet_aks_system_id = module.network.subnet_aks_system_id
  subnet_aks_app_id    = module.network.subnet_aks_app_id
}

module "acr" {
  source           = "../../shared/modules/acr"
  prefix           = var.prefix
  project          = var.project
  environment      = var.environment
  location         = var.location
  acr_sku          = var.acr_sku
  acr_admin_enabled = var.acr_admin_enabled
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = module.acr.acr_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.aks_identity_principal_id
}

module "storage" {
  source                = "../../shared/modules/storage"
  prefix                = var.prefix
  project               = var.project
  environment           = var.environment
  location              = var.location
  storage_account_tier  = var.storage_account_tier
  storage_replication_type = var.storage_replication_type
}
