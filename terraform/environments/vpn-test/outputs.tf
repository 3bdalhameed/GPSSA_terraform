output "vm_public_ip" {
  value       = azurerm_public_ip.vm.ip_address
  description = "SSH into this IP to run connectivity tests"
}

output "vm_private_ip" {
  value       = azurerm_network_interface.vm.private_ip_address
  description = "Private IP of the GPSSA-sim test VM (192.168.1.x)"
}

output "hub_vpn_gw_public_ip" {
  value       = local.hub_gw_ip
  description = "Public IP of the Hub VPN Gateway"
}

output "gpssa_vpn_gw_public_ip" {
  value       = azurerm_public_ip.gpssa_gw.ip_address
  description = "Public IP of the GPSSA-sim VPN Gateway"
}

output "ssh_command" {
  value       = "ssh ${var.vm_admin_username}@${azurerm_public_ip.vm.ip_address}"
  description = "SSH into the GPSSA-sim VM to run ping tests"
}

output "tunnel_status_command" {
  value = "az network vpn-connection show --name conn-hub-to-gpssa --resource-group ${local.hub_rg_name} --query \"{status:connectionStatus,ingressBytes:ingressBytesTransferred,egressBytes:egressBytesTransferred}\""
  description = "Run this to check tunnel status after apply"
}
