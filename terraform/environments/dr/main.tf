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
    environment = var.environment
    project     = var.project
  }
}

# ── Primary hub — needed for hub-to-hub peering and DNS zones ─────────────────

data "azurerm_virtual_network" "primary_hub" {
  name                = var.primary_hub_vnet_name
  resource_group_name = var.primary_hub_resource_group_name
}

data "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.primary_hub_resource_group_name
}

# ══════════════════════════════════════════════════════════════════════════════
# DR HUB (UAE Central)
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_resource_group" "dr_hub" {
  name     = "rg-eip-dr-hub"
  location = var.dr_location
  tags     = local.tags
}

resource "azurerm_virtual_network" "dr_hub_vnet" {
  name                = "eip-dr-hub-vnet"
  address_space       = [var.dr_hub_vnet_cidr]
  location            = azurerm_resource_group.dr_hub.location
  resource_group_name = azurerm_resource_group.dr_hub.name
  tags                = local.tags
}

resource "azurerm_subnet" "dr_firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.dr_hub.name
  virtual_network_name = azurerm_virtual_network.dr_hub_vnet.name
  address_prefixes     = [var.dr_firewall_subnet_cidr]
}

resource "azurerm_subnet" "dr_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.dr_hub.name
  virtual_network_name = azurerm_virtual_network.dr_hub_vnet.name
  address_prefixes     = [var.dr_gateway_subnet_cidr]
}

# ── DR Firewall Policy ────────────────────────────────────────────────────────

resource "azurerm_firewall_policy" "dr" {
  name                = "fwpol-eip-dr"
  resource_group_name = azurerm_resource_group.dr_hub.name
  location            = var.dr_location
  sku                 = var.firewall_sku_tier
  tags                = local.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "dr_aks_egress" {
  name               = "aks-egress"
  firewall_policy_id = azurerm_firewall_policy.dr.id
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

    rule {
      name                  = "aks-tunnel-tcp"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["AzureCloud.${var.dr_location}"]
      destination_ports     = ["9000"]
    }

    rule {
      name                  = "aks-tunnel-udp"
      protocols             = ["UDP"]
      source_addresses      = ["*"]
      destination_addresses = ["AzureCloud.${var.dr_location}"]
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
      destination_fqdns = ["*.hcp.${var.dr_location}.azmk8s.io"]
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
  }
}

# ── DR Firewall ───────────────────────────────────────────────────────────────

resource "azurerm_public_ip" "dr_firewall" {
  name                = "pip-fw-eip-dr-hub"
  resource_group_name = azurerm_resource_group.dr_hub.name
  location            = var.dr_location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_firewall" "dr" {
  name                = "fw-eip-dr-hub"
  location            = var.dr_location
  resource_group_name = azurerm_resource_group.dr_hub.name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku_tier
  firewall_policy_id  = azurerm_firewall_policy.dr.id
  tags                = local.tags

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.dr_firewall.id
    public_ip_address_id = azurerm_public_ip.dr_firewall.id
  }
}

# ── DR VPN Gateway ────────────────────────────────────────────────────────────

resource "azurerm_public_ip" "dr_vpn_gateway" {
  name                = "pip-vgw-eip-dr-hub"
  resource_group_name = azurerm_resource_group.dr_hub.name
  location            = var.dr_location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_virtual_network_gateway" "dr" {
  name                = "vgw-eip-dr-hub"
  resource_group_name = azurerm_resource_group.dr_hub.name
  location            = var.dr_location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = var.vpn_gateway_sku
  active_active       = false
  enable_bgp          = false
  tags                = local.tags

  ip_configuration {
    name                          = "gw-ipconfig"
    public_ip_address_id          = azurerm_public_ip.dr_vpn_gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.dr_gateway.id
  }
}

# ── Hub-to-Hub Global VNet Peering (UAE North ↔ UAE Central) ──────────────────

resource "azurerm_virtual_network_peering" "primary_hub_to_dr_hub" {
  name                      = "peer-primary-hub-to-dr-hub"
  resource_group_name       = var.primary_hub_resource_group_name
  virtual_network_name      = var.primary_hub_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.dr_hub_vnet.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}

resource "azurerm_virtual_network_peering" "dr_hub_to_primary_hub" {
  name                      = "peer-dr-hub-to-primary-hub"
  resource_group_name       = azurerm_resource_group.dr_hub.name
  virtual_network_name      = azurerm_virtual_network.dr_hub_vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.primary_hub.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}

# ══════════════════════════════════════════════════════════════════════════════
# DR SPOKE (UAE Central)
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_resource_group" "network" {
  name     = "rg-${var.prefix}-${var.environment}-network-spoke"
  location = var.dr_location
  tags     = local.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-${var.environment}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  tags                = local.tags
}

resource "azurerm_subnet" "aks_sys" {
  name                 = "snet-${var.prefix}-${var.environment}-aks-sys"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_aks_sys_cidr]
}

resource "azurerm_subnet" "aks_devops" {
  name                 = "snet-${var.prefix}-${var.environment}-aks-devops"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_aks_devops_cidr]
}

resource "azurerm_subnet" "shared" {
  name                              = "snet-${var.prefix}-${var.environment}-shared"
  resource_group_name               = azurerm_resource_group.network.name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = [var.subnet_shared_cidr]
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_subnet" "resv" {
  name                 = "snet-${var.prefix}-${var.environment}-resv"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_resv_cidr]
}

resource "azurerm_subnet" "aks_app01" {
  name                 = "snet-${var.prefix}-${var.environment}-aks-app01"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_aks_app01_cidr]
}

# ── Route table: force DR spoke traffic through DR firewall ───────────────────

resource "azurerm_route_table" "spoke" {
  name                          = "rt-${var.prefix}-${var.environment}"
  location                      = var.dr_location
  resource_group_name           = azurerm_resource_group.network.name
  bgp_route_propagation_enabled = false

  route {
    name                   = "to-dr-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.dr.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "aks_sys" {
  subnet_id      = azurerm_subnet.aks_sys.id
  route_table_id = azurerm_route_table.spoke.id
}

resource "azurerm_subnet_route_table_association" "aks_devops" {
  subnet_id      = azurerm_subnet.aks_devops.id
  route_table_id = azurerm_route_table.spoke.id
}

resource "azurerm_subnet_route_table_association" "aks_app01" {
  subnet_id      = azurerm_subnet.aks_app01.id
  route_table_id = azurerm_route_table.spoke.id
}

# ── DR Spoke ↔ DR Hub peering ─────────────────────────────────────────────────

resource "azurerm_virtual_network_peering" "spoke_to_dr_hub" {
  name                      = "peer-${var.environment}-to-dr-hub"
  resource_group_name       = azurerm_resource_group.network.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = azurerm_virtual_network.dr_hub_vnet.id
  allow_forwarded_traffic   = true
  use_remote_gateways       = false
}

resource "azurerm_virtual_network_peering" "dr_hub_to_spoke" {
  name                      = "peer-dr-hub-to-${var.environment}"
  resource_group_name       = azurerm_resource_group.dr_hub.name
  virtual_network_name      = azurerm_virtual_network.dr_hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
}

# ── Storage ───────────────────────────────────────────────────────────────────

module "storage" {
  source                   = "../../shared/modules/storage"
  prefix                   = var.prefix
  project                  = var.project
  environment              = var.environment
  location                 = var.dr_location
  rg_name_override         = "rg-${var.prefix}-${var.environment}-storage"
  storage_account_tier     = var.storage_account_tier
  storage_replication_type = var.storage_replication_type
}

# ── Private DNS Zone VNet link ─────────────────────────────────────────────────

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob_dr" {
  name                  = "link-${var.environment}-storage-blob"
  resource_group_name   = var.primary_hub_resource_group_name
  private_dns_zone_name = data.azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

# ── Private Endpoint: pe-eip-storage-dr ───────────────────────────────────────

resource "azurerm_private_endpoint" "storage" {
  name                = "pe-${var.prefix}-storage-${var.environment}"
  location            = var.dr_location
  resource_group_name = module.storage.resource_group_name
  subnet_id           = azurerm_subnet.shared.id

  private_service_connection {
    name                           = "psc-${var.prefix}-storage-${var.environment}"
    private_connection_resource_id = module.storage.storage_account_id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "dns-group-storage-blob"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.storage_blob.id]
  }
}
