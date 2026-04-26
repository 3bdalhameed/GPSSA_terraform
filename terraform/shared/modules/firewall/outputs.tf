output "firewall_id" {
  value       = azurerm_firewall.fw.id
  description = "ID of the Azure Firewall"
}

output "firewall_private_ip" {
  value       = azurerm_firewall.fw.ip_configuration[0].private_ip_address
  description = "Private IP address of the Azure Firewall"
}

output "firewall_public_ip" {
  value       = azurerm_public_ip.fw.ip_address
  description = "Public IP address of the Azure Firewall"
}
