# ─────────────────────────────────────────────
# modules/vpn/main.tf
# VPN Gateway + Local Network Gateways + Connections to GPSSA
# ─────────────────────────────────────────────

resource "azurerm_public_ip" "vpn_gateway" {
  name                = "pip-vpngw-hub"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "vpn" {
  name                = "vpngw-hub"
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw2"
  active_active       = false
  enable_bgp          = false
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig-vpngw"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.gateway_subnet_id
  }
}

# ── Local Network Gateways (GPSSA segments) ──
locals {
  gpssa_segments = {
    prod = var.gpssa_prod_cidr
    stg  = var.gpssa_stg_cidr
    dev  = var.gpssa_dev_cidr
  }
}

resource "azurerm_local_network_gateway" "gpssa" {
  for_each            = local.gpssa_segments
  name                = "lgw-gpssa-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  gateway_address     = var.gpssa_vpn_public_ip
  address_space       = [each.value]
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway_connection" "gpssa" {
  for_each                   = local.gpssa_segments
  name                       = "vpncon-gpssa-${each.key}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn.id
  local_network_gateway_id   = azurerm_local_network_gateway.gpssa[each.key].id
  shared_key                 = var.vpn_shared_key
  tags                       = var.tags
}
