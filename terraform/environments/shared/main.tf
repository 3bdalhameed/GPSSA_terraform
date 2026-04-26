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

# VPN Gateway requires a subnet named exactly "GatewaySubnet" with a /27 minimum
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.gateway_subnet_cidr]
}

# ── Firewall Policy ────────────────────────────────────────────────────────────

resource "azurerm_firewall_policy" "main" {
  name                = "fwpol-${var.prefix}"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.location
  sku                 = var.firewall_sku_tier
  tags                = local.tags
}

# Required egress rules so AKS nodes can provision and pull packages
resource "azurerm_firewall_policy_rule_collection_group" "aks_egress" {
  name               = "aks-egress"
  firewall_policy_id = azurerm_firewall_policy.main.id
  priority           = 100

  network_rule_collection {
    name     = "aks-network"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "ntp"
      protocols             = ["UDP"]
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }

    rule {
      name                  = "dns"
      protocols             = ["UDP"]
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["53"]
    }

    # AKS tunneled control-plane traffic
    rule {
      name                  = "aks-tunnel-tcp"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["AzureCloud.${var.location}"]
      destination_ports     = ["9000"]
    }

    rule {
      name                  = "aks-tunnel-udp"
      protocols             = ["UDP"]
      source_addresses      = ["*"]
      destination_addresses = ["AzureCloud.${var.location}"]
      destination_ports     = ["1194"]
    }
  }

  application_rule_collection {
    name     = "aks-application"
    priority = 200
    action   = "Allow"

    rule {
      name              = "aks-api-server"
      source_addresses  = ["*"]
      destination_fqdns = ["*.hcp.${var.location}.azmk8s.io"]
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name              = "mcr"
      source_addresses  = ["*"]
      destination_fqdns = ["mcr.microsoft.com", "*.data.mcr.microsoft.com"]
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
    }

    rule {
      name              = "azure-management"
      source_addresses  = ["*"]
      destination_fqdns = ["management.azure.com", "login.microsoftonline.com"]
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name              = "aks-packages"
      source_addresses  = ["*"]
      destination_fqdns = ["packages.microsoft.com", "acs-mirror.azureedge.net"]
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
    }

    rule {
      name              = "ubuntu-packages"
      source_addresses  = ["*"]
      destination_fqdns = ["security.ubuntu.com", "azure.archive.ubuntu.com", "changelogs.ubuntu.com"]
      protocols {
        type = "Http"
        port = 80
      }
    }
  }
}

module "firewall" {
  source              = "../../shared/modules/firewall"
  prefix              = var.prefix
  project             = var.project
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  firewall_subnet_id  = azurerm_subnet.firewall.id
  firewall_policy_id  = azurerm_firewall_policy.main.id
  sku_tier            = var.firewall_sku_tier
  tags                = local.tags
}

# ── VPN Gateway ───────────────────────────────────────────────────────────────

module "vpn_gateway" {
  source              = "../../shared/modules/vpn_gateway"
  prefix              = var.prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  subnet_id           = azurerm_subnet.gateway.id
  sku                 = var.vpn_gateway_sku
  tags                = local.tags
}

# App Gateway is provisioned separately once public IP quota is increased
