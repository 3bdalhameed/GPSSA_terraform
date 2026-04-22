output "firewall_id" {
  value       = azurerm_firewall.main.id
  description = "ID of the Azure Firewall"
}

output "firewall_name" {
  value       = azurerm_firewall.main.name
  description = "Name of the Azure Firewall"
}

output "firewall_private_ip" {
  value       = azurerm_firewall.main.ip_configuration[0].private_ip_address
  description = "Private IP of the firewall (next-hop for UDRs)"
}

output "firewall_public_ip" {
  value       = azurerm_public_ip.firewall.ip_address
  description = "Public IP of the firewall"
}

output "firewall_policy_id" {
  value       = azurerm_firewall_policy.main.id
  description = "ID of the firewall policy"
}
