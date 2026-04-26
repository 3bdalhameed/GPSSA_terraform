output "gpssa_vm_public_ip" {
  value       = azurerm_public_ip.gpssa_vm.ip_address
  description = "SSH into this IP to run connectivity tests"
}

output "gpssa_vm_private_ip" {
  value       = azurerm_network_interface.gpssa_vm.private_ip_address
  description = "Private IP of the GPSSA-sim test VM"
}

output "hub_vpn_gateway_public_ip" {
  value       = local.hub_gw_public_ip
  description = "Public IP of the Hub VPN Gateway (from shared state)"
}

output "gpssa_vpn_gateway_public_ip" {
  value       = azurerm_public_ip.gpssa_gw.ip_address
  description = "Public IP of the GPSSA-sim VPN Gateway"
}

output "ssh_command" {
  value       = "ssh ${var.vm_admin_username}@${azurerm_public_ip.gpssa_vm.ip_address}"
  description = "Command to SSH into the GPSSA-sim test VM"
}

output "check_tunnel_command" {
  value = <<-EOT
    az network vpn-connection show \
      --name conn-vpntest-hub-to-gpssa \
      --resource-group ${local.hub_resource_group_name} \
      --query "{status:connectionStatus,ingressBytes:ingressBytesTransferred,egressBytes:egressBytesTransferred}"
  EOT
  description = "Azure CLI command to check VPN tunnel status"
}
