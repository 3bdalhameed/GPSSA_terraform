output "hub_vpn_gateway_public_ip" {
  value       = azurerm_public_ip.hub_gw.ip_address
  description = "Public IP of the Hub VPN Gateway"
}

output "gpssa_sim_vpn_gateway_public_ip" {
  value       = azurerm_public_ip.gpssa_gw.ip_address
  description = "Public IP of the simulated GPSSA VPN Gateway"
}

output "gpssa_vm_public_ip" {
  value       = azurerm_public_ip.gpssa_vm.ip_address
  description = "SSH into this VM to run connectivity tests: ssh azureuser@<ip>"
}

output "gpssa_vm_private_ip" {
  value       = azurerm_network_interface.gpssa_vm.private_ip_address
  description = "Private IP of the GPSSA-sim test VM (192.168.1.x)"
}

output "spoke_vm_private_ip" {
  value       = azurerm_network_interface.spoke_vm.private_ip_address
  description = "Private IP of the spoke test VM — ping this from GPSSA-sim to prove VPN works"
}

output "vpn_connection_hub_status" {
  value       = azurerm_virtual_network_gateway_connection.hub_to_gpssa.id
  description = "Resource ID of hub→GPSSA connection (check Status in Portal)"
}

output "test_command" {
  value       = "ssh ${var.vm_admin_username}@${azurerm_public_ip.gpssa_vm.ip_address} 'ping -c 4 ${azurerm_network_interface.spoke_vm.private_ip_address}'"
  description = "Run this command after apply to verify end-to-end VPN connectivity"
}
