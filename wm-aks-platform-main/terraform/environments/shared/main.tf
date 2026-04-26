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

locals {
  common_tags = {
    project    = var.project
    managed_by = "terraform"
  }
}

resource "azurerm_resource_group" "shared" {
  name     = "rg-shared-${var.prefix}-${var.location}"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "shared" {
  name                = "vnet-shared-${var.prefix}"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.shared.location
  resource_group_name = azurerm_resource_group.shared.name
  tags                = local.common_tags
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.shared.name
  virtual_network_name = azurerm_virtual_network.shared.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 0)]
}

module "firewall" {
  source              = "../../shared/modules/firewall"
  prefix              = var.prefix
  project             = var.project
  environment         = "shared"
  location            = var.location
  resource_group_name = azurerm_resource_group.shared.name
  firewall_subnet_id  = azurerm_subnet.firewall.id
  sku_tier            = var.firewall_sku_tier
}
