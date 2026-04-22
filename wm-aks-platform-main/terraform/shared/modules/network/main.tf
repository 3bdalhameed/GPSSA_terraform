locals {
  common_tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-network-${var.prefix}-${var.environment}-${var.location}"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags
}

resource "azurerm_subnet" "subnet1" {
  name                 = "subnet-web"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 1)]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "subnet-aks-system"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 2)]
}

resource "azurerm_subnet" "subnet3" {
  name                 = "subnet-aks-app"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 3)]
}

resource "azurerm_subnet" "subnet4" {
  name                 = "subnet-db"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 4)]
}

# AzureFirewallSubnet — name is mandated by Azure
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 5)]
}

# ── Network Security Groups ──────────────────
resource "azurerm_network_security_group" "web" {
  name                = "nsg-${var.prefix}-${var.environment}-web"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  security_rule {
    name                       = "allow-https-in"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "aks_system" {
  name                = "nsg-${var.prefix}-${var.environment}-aks-system"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags
}

resource "azurerm_network_security_group" "aks_app" {
  name                = "nsg-${var.prefix}-${var.environment}-aks-app"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags
}

resource "azurerm_network_security_group" "db" {
  name                = "nsg-${var.prefix}-${var.environment}-db"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  security_rule {
    name                       = "deny-internet-in"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_subnet_network_security_group_association" "aks_system" {
  subnet_id                 = azurerm_subnet.subnet2.id
  network_security_group_id = azurerm_network_security_group.aks_system.id
}

resource "azurerm_subnet_network_security_group_association" "aks_app" {
  subnet_id                 = azurerm_subnet.subnet3.id
  network_security_group_id = azurerm_network_security_group.aks_app.id
}

resource "azurerm_subnet_network_security_group_association" "db" {
  subnet_id                 = azurerm_subnet.subnet4.id
  network_security_group_id = azurerm_network_security_group.db.id
}

# ── Route Table (force egress via hub firewall) ─
resource "azurerm_route_table" "spoke" {
  count                         = var.enable_firewall_routing ? 1 : 0
  name                          = "rt-${var.prefix}-${var.environment}"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.rg.name
  bgp_route_propagation_enabled = false
  tags                          = local.common_tags

  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip
  }
}

resource "azurerm_subnet_route_table_association" "aks_system" {
  count          = var.enable_firewall_routing ? 1 : 0
  subnet_id      = azurerm_subnet.subnet2.id
  route_table_id = azurerm_route_table.spoke[0].id
}

resource "azurerm_subnet_route_table_association" "aks_app" {
  count          = var.enable_firewall_routing ? 1 : 0
  subnet_id      = azurerm_subnet.subnet3.id
  route_table_id = azurerm_route_table.spoke[0].id
}

# ── Hub ↔ Spoke VNet Peering ─────────────────
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  count                     = var.enable_hub_peering ? 1 : 0
  name                      = "peer-${var.prefix}-${var.environment}-to-hub"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = var.hub_vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = var.use_remote_gateways
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  count                     = var.enable_hub_peering ? 1 : 0
  name                      = "peer-hub-to-${var.prefix}-${var.environment}"
  resource_group_name       = var.hub_resource_group_name
  virtual_network_name      = var.hub_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = var.use_remote_gateways
}
