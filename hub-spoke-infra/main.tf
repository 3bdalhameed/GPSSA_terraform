terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
  required_version = ">= 1.5.0"

  # Uncomment to use Azure backend
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "stgtfstate"
  #   container_name       = "tfstate"
  #   key                  = "hub-spoke-infra.tfstate"
  # }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "hub" {
  source              = "./modules/hub"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  hub_vnet_cidr       = var.hub_vnet_cidr
  firewall_subnet_cidr = var.hub_firewall_subnet_cidr
  gateway_subnet_cidr  = var.hub_gateway_subnet_cidr
  tags                = var.tags
}

module "vpn" {
  source              = "./modules/vpn"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  gateway_subnet_id   = module.hub.gateway_subnet_id
  vpn_shared_key      = var.vpn_shared_key
  gpssa_vpn_public_ip = var.gpssa_vpn_public_ip
  gpssa_prod_cidr     = var.gpssa_prod_cidr
  gpssa_stg_cidr      = var.gpssa_stg_cidr
  gpssa_dev_cidr      = var.gpssa_dev_cidr
  tags                = var.tags
}

module "spokes" {
  source              = "./modules/spokes"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  hub_vnet_id         = module.hub.vnet_id
  firewall_private_ip = module.hub.firewall_private_ip
  vpn_gateway_id      = module.vpn.gateway_id
  spokes              = var.spokes
  tags                = var.tags
}

module "aks" {
  source              = "./modules/aks"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  spoke_subnet_ids    = module.spokes.aks_subnet_ids
  kubernetes_version  = var.kubernetes_version
  aks_node_counts     = var.aks_node_counts
  aks_vm_sizes        = var.aks_vm_sizes
  tags                = var.tags
}
