output "gateway_id" {
  value       = azurerm_virtual_network_gateway.gw.id
  description = "Resource ID of the VPN Gateway"
}

output "gateway_name" {
  value       = azurerm_virtual_network_gateway.gw.name
  description = "Name of the VPN Gateway"
}

output "gateway_public_ip" {
  value       = azurerm_public_ip.gw.ip_address
  description = "Public IP address of the VPN Gateway"
}
