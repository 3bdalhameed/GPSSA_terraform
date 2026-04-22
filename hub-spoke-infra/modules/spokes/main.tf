# ─────────────────────────────────────────────
# modules/spokes/main.tf
# Spoke VNets, AKS subnets, peerings, route tables
# ─────────────────────────────────────────────

resource "azurerm_virtual_network" "spoke" {
  for_each            = var.spokes
  name                = "vnet-${each.key}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [each.value.vnet_cidr]
  tags                = merge(var.tags, { environment = each.key })
}

resource "azurerm_subnet" "aks" {
  for_each             = var.spokes
  name                 = "snet-aks-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke[each.key].name
  address_prefixes     = [each.value.aks_subnet_cidr]
}

# ── VNet Peerings ────────────────────────────
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each                  = var.spokes
  name                      = "peer-${each.key}-to-hub"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.spoke[each.key].name
  remote_virtual_network_id = var.hub_vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true

  depends_on = [var.vpn_gateway_id]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each                  = var.spokes
  name                      = "peer-hub-to-${each.key}"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = "vnet-hub"
  remote_virtual_network_id = azurerm_virtual_network.spoke[each.key].id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

# ── Route Tables (force traffic via Firewall) ─
resource "azurerm_route_table" "spoke" {
  for_each                      = var.spokes
  name                          = "rt-${each.key}-pe"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = true
  tags                          = var.tags

  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip
  }
}

resource "azurerm_subnet_route_table_association" "aks" {
  for_each       = var.spokes
  subnet_id      = azurerm_subnet.aks[each.key].id
  route_table_id = azurerm_route_table.spoke[each.key].id
}
