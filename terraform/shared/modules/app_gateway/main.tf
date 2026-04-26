# AGW v2 requires inbound 65200-65535 from GatewayManager for health probes
resource "azurerm_network_security_group" "agw" {
  name                = "nsg-agw-${var.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  security_rule {
    name                       = "allow-gateway-manager"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-azure-lb"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-http"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-https"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "agw" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.agw.id
}

resource "azurerm_public_ip" "agw" {
  name                = "pip-agw-${var.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_application_gateway" "agw" {
  name                = "agw-${var.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  sku {
    name     = var.sku_name
    tier     = var.sku_tier
    capacity = var.capacity
  }

  gateway_ip_configuration {
    name      = "agw-ip-config"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "port-80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "agw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.agw.id
  }

  dynamic "backend_address_pool" {
    for_each = var.backends
    content {
      name         = "pool-${backend_address_pool.key}"
      ip_addresses = backend_address_pool.value.ip_addresses
      fqdns        = backend_address_pool.value.fqdns
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.backends
    content {
      name                  = "http-settings-${backend_http_settings.key}"
      cookie_based_affinity = "Disabled"
      port                  = 80
      protocol              = "Http"
      request_timeout       = 60
    }
  }

  dynamic "http_listener" {
    for_each = var.backends
    content {
      name                           = "listener-${http_listener.key}"
      frontend_ip_configuration_name = "agw-frontend-ip"
      frontend_port_name             = "port-80"
      protocol                       = "Http"
      host_name                      = http_listener.value.hostname != "" ? http_listener.value.hostname : null
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.backends
    content {
      name                       = "rule-${request_routing_rule.key}"
      rule_type                  = "Basic"
      http_listener_name         = "listener-${request_routing_rule.key}"
      backend_address_pool_name  = "pool-${request_routing_rule.key}"
      backend_http_settings_name = "http-settings-${request_routing_rule.key}"
      priority                   = request_routing_rule.value.priority
    }
  }

  depends_on = [azurerm_subnet_network_security_group_association.agw]
}
