output "app_gateway_id" {
  value       = azurerm_application_gateway.agw.id
  description = "ID of the Application Gateway"
}

output "app_gateway_name" {
  value       = azurerm_application_gateway.agw.name
  description = "Name of the Application Gateway"
}

output "app_gateway_public_ip" {
  value       = azurerm_public_ip.agw.ip_address
  description = "Public IP address of the Application Gateway"
}
