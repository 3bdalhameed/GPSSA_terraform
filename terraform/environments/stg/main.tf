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

# ── Hub resources — read directly from Azure (no remote state dependency) ──────

data "azurerm_virtual_network" "hub" {
  name                = var.hub_vnet_name
  resource_group_name = var.hub_resource_group_name
}

data "azurerm_firewall" "hub" {
  name                = var.hub_firewall_name
  resource_group_name = var.hub_resource_group_name
}

# Storage blob DNS zone already exists in the hub RG — only add a VNet link for stg
data "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.hub_resource_group_name
}

# ── Network resources (spoke) ──────────────────────────────────────────────────

resource "azurerm_resource_group" "network" {
  name     = "rg-${var.prefix}-${var.environment}-network-spoke"
  location = var.location
  tags     = { environment = var.environment, project = var.project }
  lifecycle { ignore_changes = [tags] }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-${var.environment}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  tags                = { environment = var.environment, project = var.project }
}

resource "azurerm_subnet" "aks_sys" {
  name                 = "snet-${var.prefix}-${var.environment}-aks-sys"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_aks_sys_cidr]
  service_endpoints    = ["Microsoft.KeyVault"]
}

resource "azurerm_subnet" "aks_app01" {
  name                 = "snet-${var.prefix}-${var.environment}-aks-app01"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_aks_app01_cidr]
  service_endpoints    = ["Microsoft.KeyVault"]
}

# PE network policies disabled so private endpoint NICs bypass the route table
resource "azurerm_subnet" "shared" {
  name                              = "snet-${var.prefix}-${var.environment}-shared"
  resource_group_name               = azurerm_resource_group.network.name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = [var.subnet_shared_cidr]
  private_endpoint_network_policies = "Disabled"
  service_endpoints                 = ["Microsoft.KeyVault"]
}

resource "azurerm_subnet" "resv" {
  name                 = "snet-${var.prefix}-${var.environment}-resv"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_resv_cidr]
  service_endpoints    = ["Microsoft.KeyVault"]
}

resource "azurerm_subnet" "aks_app02" {
  name                 = "snet-${var.prefix}-${var.environment}-aks-app02"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_aks_app02_cidr]
  service_endpoints    = ["Microsoft.KeyVault"]
}

# ── Storage ───────────────────────────────────────────────────────────────────

module "storage" {
  source                        = "../../shared/modules/storage"
  prefix                        = var.prefix
  project                       = var.project
  environment                   = var.environment
  location                      = var.location
  rg_name_override              = "rg-${var.prefix}-${var.environment}-storage"
  storage_account_name_override = var.storage_account_name_override
  storage_account_tier          = var.storage_account_tier
  storage_replication_type      = var.storage_replication_type
}

# ── Route table: force spoke traffic through hub firewall ─────────────────────

resource "azurerm_route_table" "spoke" {
  name                          = "rt-${var.prefix}-${var.environment}"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.network.name
  bgp_route_propagation_enabled = true

  route {
    name                   = "to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = data.azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "aks_sys" {
  subnet_id      = azurerm_subnet.aks_sys.id
  route_table_id = azurerm_route_table.spoke.id
}

resource "azurerm_subnet_route_table_association" "aks_app01" {
  subnet_id      = azurerm_subnet.aks_app01.id
  route_table_id = azurerm_route_table.spoke.id
}

resource "azurerm_subnet_route_table_association" "aks_app02" {
  subnet_id      = azurerm_subnet.aks_app02.id
  route_table_id = azurerm_route_table.spoke.id
}

# ── Hub-spoke peering ──────────────────────────────────────────────────────────

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-${var.environment}-to-hub"
  resource_group_name       = azurerm_resource_group.network.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
  use_remote_gateways       = false
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-${var.environment}"
  resource_group_name       = var.hub_resource_group_name
  virtual_network_name      = data.azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
}

# ── Private DNS Zone VNet link ─────────────────────────────────────────────────

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob_stg" {
  name                  = "link-${var.environment}-storage-blob"
  resource_group_name   = var.hub_resource_group_name
  private_dns_zone_name = data.azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

# ── Private Endpoint: pe-eip-storage-stg ──────────────────────────────────────

resource "azurerm_private_endpoint" "storage" {
  name                = "pe-${var.prefix}-storage-${var.environment}"
  location            = var.location
  resource_group_name = module.storage.resource_group_name
  subnet_id           = azurerm_subnet.shared.id

  private_service_connection {
    name                           = "psc-${var.prefix}-storage-${var.environment}"
    private_connection_resource_id = module.storage.storage_account_id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.storage_blob.id]
  }
}
