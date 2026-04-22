output "gateway_id" {
  value = azurerm_virtual_network_gateway.vpn.id
}

output "gateway_public_ip" {
  description = "Share this IP with the GPSSA team for VPN tunnel configuration"
  value       = azurerm_public_ip.vpn_gateway.ip_address
}
