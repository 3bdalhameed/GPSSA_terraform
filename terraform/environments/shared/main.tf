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
  tags = {
    project = var.project
    tier    = "shared"
  }
}

resource "azurerm_resource_group" "hub" {
  name     = "rg-hub-${var.prefix}-${var.location}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${var.prefix}"
  address_space       = [var.hub_vnet_cidr]
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.tags
}

# Azure Firewall requires a subnet named exactly "AzureFirewallSubnet" with a /26 minimum
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.firewall_subnet_cidr]
}

module "firewall" {
  source              = "../../shared/modules/firewall"
  prefix              = var.prefix
  project             = var.project
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  firewall_subnet_id  = azurerm_subnet.firewall.id
  sku_tier            = var.firewall_sku_tier
  tags                = local.tags
}
