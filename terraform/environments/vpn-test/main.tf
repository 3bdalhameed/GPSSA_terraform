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

# Pull the Hub VPN Gateway details provisioned by the shared environment
data "terraform_remote_state" "shared" {
  backend = "local"
  config = {
    path = "${path.module}/../shared/terraform.tfstate"
  }
}

locals {
  tags = {
    project     = "gpssa"
    environment = "vpn-test"
  }

  hub_gw_public_ip        = data.terraform_remote_state.shared.outputs.vpn_gateway_public_ip
  hub_gw_id               = data.terraform_remote_state.shared.outputs.vpn_gateway_id
  hub_resource_group_name = data.terraform_remote_state.shared.outputs.hub_resource_group_name
  hub_vnet_cidr           = data.terraform_remote_state.shared.outputs.hub_vnet_cidr
}

# ══════════════════════════════════════════════════════════════════════════════
# GPSSA-SIM RESOURCE GROUP
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_resource_group" "gpssa_sim" {
  name     = "rg-vpntest-gpssa-sim-${var.prefix}"
  location = var.location
  tags     = local.tags
}

# ══════════════════════════════════════════════════════════════════════════════
# GPSSA-SIM VNET  (192.168.0.0/16)
# Represents the on-premises GPSSA network
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_virtual_network" "gpssa_sim" {
  name                = "vnet-vpntest-gpssa-sim"
  address_space       = [var.gpssa_sim_vnet_cidr]
  location            = var.location
  resource_group_name = azurerm_resource_group.gpssa_sim.name
  tags                = local.tags
}

resource "azurerm_subnet" "gpssa_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.gpssa_sim.name
  virtual_network_name = azurerm_virtual_network.gpssa_sim.name
  address_prefixes     = [var.gpssa_gateway_subnet_cidr]
}

resource "azurerm_subnet" "gpssa_vm" {
  name                 = "subnet-vm"
  resource_group_name  = azurerm_resource_group.gpssa_sim.name
  virtual_network_name = azurerm_virtual_network.gpssa_sim.name
  address_prefixes     = [var.gpssa_vm_subnet_cidr]
}

# ══════════════════════════════════════════════════════════════════════════════
# GPSSA-SIM VPN GATEWAY
# NOTE: takes 20-45 minutes to provision
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_public_ip" "gpssa_gw" {
  name                = "pip-vpntest-gpssa-gw"
  resource_group_name = azurerm_resource_group.gpssa_sim.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_virtual_network_gateway" "gpssa_sim" {
  name                = "vpngw-vpntest-gpssa-sim"
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
# Hub side: "I know the GPSSA-sim network at this public IP + CIDR"
# GPSSA side: "I know the Azure network at this public IP + CIDR"
# ══════════════════════════════════════════════════════════════════════════════

# Created in the HUB resource group (alongside the Hub VPN GW)
resource "azurerm_local_network_gateway" "hub_knows_gpssa" {
  name                = "lng-vpntest-hub-to-gpssa"
  resource_group_name = local.hub_resource_group_name
  location            = var.location
  gateway_address     = azurerm_public_ip.gpssa_gw.ip_address
  address_space       = [var.gpssa_sim_vnet_cidr]
  tags                = local.tags
}

# Created in the GPSSA-sim resource group
resource "azurerm_local_network_gateway" "gpssa_knows_hub" {
  name                = "lng-vpntest-gpssa-to-hub"
  resource_group_name = azurerm_resource_group.gpssa_sim.name
  location            = var.location
  gateway_address     = local.hub_gw_public_ip
  address_space       = ["10.0.0.0/8"]
  tags                = local.tags
}

# ══════════════════════════════════════════════════════════════════════════════
# VPN CONNECTIONS  (same shared_key on both ends)
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_virtual_network_gateway_connection" "hub_to_gpssa" {
  name                       = "conn-vpntest-hub-to-gpssa"
  resource_group_name        = local.hub_resource_group_name
  location                   = var.location
  type                       = "IPsec"
  virtual_network_gateway_id = local.hub_gw_id
  local_network_gateway_id   = azurerm_local_network_gateway.hub_knows_gpssa.id
  shared_key                 = var.vpn_shared_key
  tags                       = local.tags
}

resource "azurerm_virtual_network_gateway_connection" "gpssa_to_hub" {
  name                       = "conn-vpntest-gpssa-to-hub"
  resource_group_name        = azurerm_resource_group.gpssa_sim.name
  location                   = var.location
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gpssa_sim.id
  local_network_gateway_id   = azurerm_local_network_gateway.gpssa_knows_hub.id
  shared_key                 = var.vpn_shared_key
  tags                       = local.tags
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST VM — GPSSA-SIM SIDE
# Has a public IP so you can SSH in and run ping/curl to the Azure spoke
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_public_ip" "gpssa_vm" {
  name                = "pip-vpntest-gpssa-vm"
  resource_group_name = azurerm_resource_group.gpssa_sim.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_security_group" "gpssa_vm" {
  name                = "nsg-vpntest-gpssa-vm"
  resource_group_name = azurerm_resource_group.gpssa_sim.name
  location            = var.location
  tags                = local.tags

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_source_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-from-azure"
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

resource "azurerm_network_interface" "gpssa_vm" {
  name                = "nic-vpntest-gpssa-vm"
  resource_group_name = azurerm_resource_group.gpssa_sim.name
  location            = var.location
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.gpssa_vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.gpssa_vm.id
  }
}

resource "azurerm_network_interface_security_group_association" "gpssa_vm" {
  network_interface_id      = azurerm_network_interface.gpssa_vm.id
  network_security_group_id = azurerm_network_security_group.gpssa_vm.id
}

resource "azurerm_linux_virtual_machine" "gpssa_vm" {
  name                            = "vm-vpntest-gpssa"
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
