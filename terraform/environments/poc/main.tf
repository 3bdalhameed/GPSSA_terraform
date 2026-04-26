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
    project     = var.project
    environment = "poc"
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# RESOURCE GROUPS
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_resource_group" "hub" {
  name     = "rg-poc-hub-${var.prefix}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_resource_group" "spoke" {
  name     = "rg-poc-spoke-${var.prefix}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_resource_group" "gpssa_sim" {
  name     = "rg-poc-gpssa-sim-${var.prefix}"
  location = var.location
  tags     = local.tags
}

# ══════════════════════════════════════════════════════════════════════════════
# HUB VNET  (10.0.0.0/16)
# Subnets:
#   GatewaySubnet         10.0.0.0/27   — VPN Gateway (Azure-reserved name)
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-poc-hub"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.tags
}

resource "azurerm_subnet" "hub_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.0.0/27"]
}

# ══════════════════════════════════════════════════════════════════════════════
# SPOKE VNET — simulates DEV PE VNet  (10.1.0.0/16)
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-poc-spoke-dev"
  address_space       = ["10.1.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke.name
  tags                = local.tags
}

resource "azurerm_subnet" "spoke_default" {
  name                 = "subnet-default"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.1.1.0/24"]
}

# ══════════════════════════════════════════════════════════════════════════════
# GPSSA-SIM VNET — simulates on-premises GPSSA  (192.168.0.0/16)
# Subnets:
#   GatewaySubnet         192.168.0.0/27
#   subnet-default        192.168.1.0/24  — GPSSA-sim test VM lives here
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_virtual_network" "gpssa_sim" {
  name                = "vnet-poc-gpssa-sim"
  address_space       = ["192.168.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.gpssa_sim.name
  tags                = local.tags
}

resource "azurerm_subnet" "gpssa_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.gpssa_sim.name
  virtual_network_name = azurerm_virtual_network.gpssa_sim.name
  address_prefixes     = ["192.168.0.0/27"]
}

resource "azurerm_subnet" "gpssa_default" {
  name                 = "subnet-default"
  resource_group_name  = azurerm_resource_group.gpssa_sim.name
  virtual_network_name = azurerm_virtual_network.gpssa_sim.name
  address_prefixes     = ["192.168.1.0/24"]
}

# ══════════════════════════════════════════════════════════════════════════════
# HUB ↔ SPOKE VNET PEERING
# allow_gateway_transit = true  → hub shares its VPN GW with the spoke
# use_remote_gateways   = true  → spoke uses hub's VPN GW to reach GPSSA-sim
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-spoke"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-spoke-to-hub"
  resource_group_name       = azurerm_resource_group.spoke.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
  use_remote_gateways       = true

  # Hub VPN GW must exist before spoke can use it as remote gateway
  depends_on = [azurerm_virtual_network_gateway.hub]
}

# ══════════════════════════════════════════════════════════════════════════════
# PUBLIC IPs FOR VPN GATEWAYS
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_public_ip" "hub_gw" {
  name                = "pip-poc-hub-gw"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_public_ip" "gpssa_gw" {
  name                = "pip-poc-gpssa-gw"
  resource_group_name = azurerm_resource_group.gpssa_sim.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

# ══════════════════════════════════════════════════════════════════════════════
# VPN GATEWAYS  (VpnGw1, route-based)
# NOTE: each gateway takes ~20-45 min to provision in Azure
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_virtual_network_gateway" "hub" {
  name                = "vpngw-poc-hub"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  active_active       = false
  enable_bgp          = false
  tags                = local.tags

  ip_configuration {
    name                          = "hub-gw-ipconfig"
    public_ip_address_id          = azurerm_public_ip.hub_gw.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.hub_gateway.id
  }
}

resource "azurerm_virtual_network_gateway" "gpssa_sim" {
  name                = "vpngw-poc-gpssa-sim"
  resource_group_name = azurerm_resource_group.gpssa_sim.name
  location            = var.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  active_active       = false
  enable_bgp          = false
  tags                = local.tags

  ip_configuration {
    name                          = "gpssa-gw-ipconfig"
    public_ip_address_id          = azurerm_public_ip.gpssa_gw.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gpssa_gateway.id
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# LOCAL NETWORK GATEWAYS
# Each side declares what it knows about the other side's public IP + CIDR
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_local_network_gateway" "hub_knows_gpssa" {
  name                = "lng-poc-hub-to-gpssa"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.location
  gateway_address     = azurerm_public_ip.gpssa_gw.ip_address
  address_space       = ["192.168.0.0/16"]
  tags                = local.tags
}

resource "azurerm_local_network_gateway" "gpssa_knows_hub" {
  name                = "lng-poc-gpssa-to-hub"
  resource_group_name = azurerm_resource_group.gpssa_sim.name
  location            = var.location
  gateway_address     = azurerm_public_ip.hub_gw.ip_address
  # covers hub (10.0.x.x) and spoke (10.1.x.x) via supernet
  address_space       = ["10.0.0.0/8"]
  tags                = local.tags
}

# ══════════════════════════════════════════════════════════════════════════════
# VPN CONNECTIONS  (IPsec, shared key)
# Both ends must use the same shared_key
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_virtual_network_gateway_connection" "hub_to_gpssa" {
  name                       = "conn-poc-hub-to-gpssa"
  resource_group_name        = azurerm_resource_group.hub.name
  location                   = var.location
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.hub.id
  local_network_gateway_id   = azurerm_local_network_gateway.hub_knows_gpssa.id
  shared_key                 = var.vpn_shared_key
  tags                       = local.tags
}

resource "azurerm_virtual_network_gateway_connection" "gpssa_to_hub" {
  name                       = "conn-poc-gpssa-to-hub"
  resource_group_name        = azurerm_resource_group.gpssa_sim.name
  location                   = var.location
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gpssa_sim.id
  local_network_gateway_id   = azurerm_local_network_gateway.gpssa_knows_hub.id
  shared_key                 = var.vpn_shared_key
  tags                       = local.tags
}

# ══════════════════════════════════════════════════════════════════════════════
# NSG: GPSSA-SIM TEST VM
# Allow SSH from your IP so you can log in and run ping/curl tests
# Allow all traffic from hub/spoke CIDRs (VPN tunnel traffic)
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_network_security_group" "gpssa_vm" {
  name                = "nsg-poc-gpssa-vm"
  resource_group_name = azurerm_resource_group.gpssa_sim.name
  location            = var.location
  tags                = local.tags

  security_rule {
    name                       = "allow-ssh-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.gpssa_sim_ssh_source_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-vpn-inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.0.0/8"
    destination_address_prefix = "*"
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# NSG: SPOKE TEST VM
# Allow ICMP + SSH from GPSSA-sim CIDR (comes in through VPN tunnel)
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_network_security_group" "spoke_vm" {
  name                = "nsg-poc-spoke-vm"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  tags                = local.tags

  security_rule {
    name                       = "allow-from-gpssa-sim"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "192.168.0.0/16"
    destination_address_prefix = "*"
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST VM — GPSSA-SIM SIDE
# Has a public IP so you can SSH in from your laptop
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_public_ip" "gpssa_vm" {
  name                = "pip-poc-gpssa-vm"
  resource_group_name = azurerm_resource_group.gpssa_sim.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "gpssa_vm" {
  name                = "nic-poc-gpssa-vm"
  resource_group_name = azurerm_resource_group.gpssa_sim.name
  location            = var.location
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.gpssa_default.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.gpssa_vm.id
  }
}

resource "azurerm_network_interface_security_group_association" "gpssa_vm" {
  network_interface_id      = azurerm_network_interface.gpssa_vm.id
  network_security_group_id = azurerm_network_security_group.gpssa_vm.id
}

resource "azurerm_linux_virtual_machine" "gpssa_vm" {
  name                            = "vm-poc-gpssa"
  resource_group_name             = azurerm_resource_group.gpssa_sim.name
  location                        = var.location
  size                            = "Standard_B1s"
  admin_username                  = var.vm_admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.gpssa_vm.id]
  tags                            = local.tags

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.vm_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST VM — SPOKE (DEV) SIDE
# No public IP — only reachable via VPN from GPSSA-sim
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_network_interface" "spoke_vm" {
  name                = "nic-poc-spoke-vm"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke_default.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "spoke_vm" {
  network_interface_id      = azurerm_network_interface.spoke_vm.id
  network_security_group_id = azurerm_network_security_group.spoke_vm.id
}

resource "azurerm_linux_virtual_machine" "spoke_vm" {
  name                            = "vm-poc-spoke"
  resource_group_name             = azurerm_resource_group.spoke.name
  location                        = var.location
  size                            = "Standard_B1s"
  admin_username                  = var.vm_admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.spoke_vm.id]
  tags                            = local.tags

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.vm_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
