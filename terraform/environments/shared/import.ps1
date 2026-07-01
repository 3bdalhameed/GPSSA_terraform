$SUB   = "5856841c-3e36-4255-be62-13a04c7901e3"
$RG    = "rg-eip-shared-network-hub"
$VNET  = "eip-hub-vnet"

Write-Host "Importing SHARED (hub) resources..." -ForegroundColor Cyan

# Resource Group
terraform import azurerm_resource_group.hub /subscriptions/$SUB/resourceGroups/$RG

# VNet
terraform import azurerm_virtual_network.hub /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET

# Subnets
terraform import azurerm_subnet.firewall /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/subnets/AzureFirewallSubnet
terraform import azurerm_subnet.gateway  /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/subnets/GatewaySubnet

# Firewall Policy
terraform import azurerm_firewall_policy.main /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/firewallPolicies/fwpol-eip

# Firewall
terraform import module.firewall.azurerm_public_ip.fw /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/publicIPAddresses/pip-fw-eip
terraform import module.firewall.azurerm_firewall.fw  /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/azureFirewalls/fw-eip-hub

# VPN Gateway
terraform import module.vpn_gateway.azurerm_public_ip.gw              /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/publicIPAddresses/pip-vpngw-eip
terraform import module.vpn_gateway.azurerm_virtual_network_gateway.gw /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworkGateways/vgw-eip-hub

Write-Host "SHARED import complete. Run 'terraform plan' to verify." -ForegroundColor Green
Write-Host ""
Write-Host "NOTE: The shared code has naming differences vs Azure. 'terraform plan' may show" -ForegroundColor Yellow
Write-Host "changes — review carefully before running 'terraform apply'." -ForegroundColor Yellow
