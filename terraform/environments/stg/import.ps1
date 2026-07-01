$SUB  = "5856841c-3e36-4255-be62-13a04c7901e3"
$RG   = "rg-eip-stg-network-spoke"
$RGSTORAGE = "rg-eip-stg-storage"
$RGHUB = "rg-eip-shared-network-hub"
$VNET = "eip-stg-vnet"
$HUB_VNET = "eip-hub-vnet"

Write-Host "Importing STG resources..." -ForegroundColor Cyan

# Resource Groups
terraform import azurerm_resource_group.network /subscriptions/$SUB/resourceGroups/$RG
terraform import module.storage.azurerm_resource_group.storage /subscriptions/$SUB/resourceGroups/$RGSTORAGE

# VNet
terraform import azurerm_virtual_network.vnet /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET

# Subnets
terraform import azurerm_subnet.aks_sys    /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/subnets/snet-eip-stg-aks-sys
terraform import azurerm_subnet.aks_app01  /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/subnets/snet-eip-stg-aks-app01
terraform import azurerm_subnet.shared     /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/subnets/snet-eip-stg-shared
terraform import azurerm_subnet.resv       /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/subnets/snet-eip-stg-resv
terraform import azurerm_subnet.aks_app02  /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/subnets/snet-eip-stg-aks-app02

# Route Table
terraform import azurerm_route_table.spoke /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/routeTables/rt-eip-stg

# Route Table Associations (import ID = subnet ID)
terraform import azurerm_subnet_route_table_association.aks_sys    /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/subnets/snet-eip-stg-aks-sys
terraform import azurerm_subnet_route_table_association.aks_app01  /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/subnets/snet-eip-stg-aks-app01
terraform import azurerm_subnet_route_table_association.aks_app02  /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/subnets/snet-eip-stg-aks-app02

# VNet Peerings
terraform import azurerm_virtual_network_peering.spoke_to_hub /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/virtualNetworkPeerings/peer-stg-to-hub
terraform import azurerm_virtual_network_peering.hub_to_spoke /subscriptions/$SUB/resourceGroups/$RGHUB/providers/Microsoft.Network/virtualNetworks/$HUB_VNET/virtualNetworkPeerings/peer-hub-to-stg

# Private DNS Zone VNet Link
terraform import azurerm_private_dns_zone_virtual_network_link.storage_blob_stg /subscriptions/$SUB/resourceGroups/$RGHUB/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net/virtualNetworkLinks/link-stg-storage-blob

# Storage Account
terraform import module.storage.azurerm_storage_account.storage /subscriptions/$SUB/resourceGroups/$RGSTORAGE/providers/Microsoft.Storage/storageAccounts/eipstgstorage001

# Private Endpoint
terraform import azurerm_private_endpoint.storage /subscriptions/$SUB/resourceGroups/$RGSTORAGE/providers/Microsoft.Network/privateEndpoints/pe-eip-storage-stg

Write-Host "STG import complete. Run 'terraform plan' to verify." -ForegroundColor Green
