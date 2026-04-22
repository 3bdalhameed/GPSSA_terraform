locals {
  common_tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_public_ip" "firewall" {
  name                = "pip-afw-${var.prefix}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_firewall_policy" "main" {
  name                     = "afwp-${var.prefix}-${var.environment}"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  sku                      = var.sku_tier
  threat_intelligence_mode = var.threat_intel_mode
  tags                     = local.common_tags
}

resource "azurerm_firewall_policy_rule_collection_group" "aks_egress" {
  name               = "rcg-aks-egress"
  firewall_policy_id = azurerm_firewall_policy.main.id
  priority           = 200

  application_rule_collection {
    name     = "arc-aks-required"
    priority = 200
    action   = "Allow"

    rule {
      name = "aks-fqdn-tags"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = [
        "*.hcp.${var.location}.azmk8s.io",
        "mcr.microsoft.com",
        "*.data.mcr.microsoft.com",
        "management.azure.com",
        "login.microsoftonline.com",
        "packages.microsoft.com",
        "acs-mirror.azureedge.net",
      ]
    }
  }

  network_rule_collection {
    name     = "nrc-aks-required"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "ntp"
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
      protocols             = ["UDP"]
    }

    rule {
      name                  = "dns"
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["53"]
      protocols             = ["UDP", "TCP"]
    }
  }
}

resource "azurerm_firewall" "main" {
  name                = "afw-${var.prefix}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.sku_tier
  firewall_policy_id  = azurerm_firewall_policy.main.id
  tags                = local.common_tags

  ip_configuration {
    name                 = "ipconfig-primary"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}
