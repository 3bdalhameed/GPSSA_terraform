resource "azurerm_public_ip" "gw" {
  name                = "pip-vpngw-${var.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1","2","3"]
  tags                = var.tags
}

# NOTE: provisioning takes 20-45 minutes in Azure
resource "azurerm_virtual_network_gateway" "gw" {
  name                = "vpngw-${var.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = var.sku
  active_active       = false
  enable_bgp          = false
  tags                = var.tags

  ip_configuration {
    name                          = "gw-ipconfig"
    public_ip_address_id          = azurerm_public_ip.gw.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.subnet_id
  }
}
