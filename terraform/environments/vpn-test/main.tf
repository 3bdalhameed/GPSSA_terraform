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

# Pull Hub VPN Gateway details from the shared environment state
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

  hub_gw_id    = data.terraform_remote_state.shared.outputs.vpn_gateway_id
  hub_gw_ip    = data.terraform_remote_state.shared.outputs.vpn_gateway_public_ip
  hub_rg_name  = data.terraform_remote_state.shared.outputs.hub_resource_group_name
  hub_vnet_cidr = data.terraform_remote_state.shared.outputs.hub_vnet_cidr
}

# ══════════════════════════════════════════════════════════════════════════════
# GPSSA-SIM RESOURCE GROUP + VNET (192.168.0.0/16)
# Simulates the on-premises GPSSA network
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_resource_group" "gpssa" {
  name     = "rg-vpntest-gpssa"
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "gpssa" {
  name                = "vnet-vpntest-gpssa"
  address_space       = ["192.168.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.gpssa.name
  tags                = local.tags
}

# GatewaySubnet — name is fixed by Azure
resource "azurerm_subnet" "gpssa_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.gpssa.name
  virtual_network_name = azurerm_virtual_network.gpssa.name
  address_prefixes     = ["192.168.0.0/27"]
}

# Subnet for the test VM
resource "azurerm_subnet" "gpssa_vm" {
  name                 = "subnet-vm"
  resource_group_name  = azurerm_resource_group.gpssa.name
  virtual_network_name = azurerm_virtual_network.gpssa.name
  address_prefixes     = ["192.168.1.0/24"]
}

# ══════════════════════════════════════════════════════════════════════════════
# GPSSA-SIM VPN GATEWAY  (NOTE: takes 20-45 min to provision)
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_public_ip" "gpssa_gw" {
  name                = "pip-vpntest-gpssa-gw"
  resource_group_name = azurerm_resource_group.gpssa.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_virtual_network_gateway" "gpssa" {
  name                = "vpngw-vpntest-gpssa"
  resource_group_name = azurerm_resource_group.gpssa.name
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
# Hub side  → knows GPSSA-sim public IP + 192.168.0.0/16
# GPSSA side → knows Hub public IP + 10.0.0.0/8 (covers hub + all spokes)
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_local_network_gateway" "hub_to_gpssa" {
  name                = "lng-hub-to-gpssa"
  resource_group_name = local.hub_rg_name
  location            = var.location
  gateway_address     = azurerm_public_ip.gpssa_gw.ip_address
  address_space       = ["192.168.0.0/16"]
  tags                = local.tags
}

resource "azurerm_local_network_gateway" "gpssa_to_hub" {
  name                = "lng-gpssa-to-hub"
  resource_group_name = azurerm_resource_group.gpssa.name
  location            = var.location
  gateway_address     = local.hub_gw_ip
  address_space       = ["10.0.0.0/8"]
  tags                = local.tags
}

# ══════════════════════════════════════════════════════════════════════════════
# VPN CONNECTIONS  — same shared_key on both ends
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_virtual_network_gateway_connection" "hub_to_gpssa" {
  name                       = "conn-hub-to-gpssa"
  resource_group_name        = local.hub_rg_name
  location                   = var.location
  type                       = "IPsec"
  virtual_network_gateway_id = local.hub_gw_id
  local_network_gateway_id   = azurerm_local_network_gateway.hub_to_gpssa.id
  shared_key                 = var.vpn_shared_key
  tags                       = local.tags
}

resource "azurerm_virtual_network_gateway_connection" "gpssa_to_hub" {
  name                       = "conn-gpssa-to-hub"
  resource_group_name        = azurerm_resource_group.gpssa.name
  location                   = var.location
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gpssa.id
  local_network_gateway_id   = azurerm_local_network_gateway.gpssa_to_hub.id
  shared_key                 = var.vpn_shared_key
  tags                       = local.tags
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST VM — GPSSA-SIM SIDE
# Public IP so you can SSH in and run ping/curl to Azure spoke resources
# ══════════════════════════════════════════════════════════════════════════════

resource "azurerm_public_ip" "vm" {
  name                = "pip-vpntest-vm"
  resource_group_name = azurerm_resource_group.gpssa.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_security_group" "vm" {
  name                = "nsg-vpntest-vm"
  resource_group_name = azurerm_resource_group.gpssa.name
  location            = var.location
  tags                = local.tags

  # SSH from your laptop only
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

  # Allow all traffic returning from Azure through the VPN tunnel
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

resource "azurerm_network_interface" "vm" {
  name                = "nic-vpntest-vm"
  resource_group_name = azurerm_resource_group.gpssa.name
  location            = var.location
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.gpssa_vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

resource "azurerm_network_interface_security_group_association" "vm" {
  network_interface_id      = azurerm_network_interface.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "vm-vpntest-gpssa"
  resource_group_name             = azurerm_resource_group.gpssa.name
  location                        = var.location
  size                            = "Standard_B1s"
  admin_username                  = var.vm_admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.vm.id]
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
