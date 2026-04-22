output "vnet_id" {
  value = azurerm_virtual_network.hub.id
}

output "gateway_subnet_id" {
  value = azurerm_subnet.gateway.id
}

output "firewall_private_ip" {
  value = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  value = azurerm_public_ip.firewall.ip_address
}
