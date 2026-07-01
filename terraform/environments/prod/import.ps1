$SUB      = "5856841c-3e36-4255-be62-13a04c7901e3"
$RG       = "rg-eip-prd-network-spoke"
$RGSTORAGE = "rg-eip-prd-storage"
$RGHUB    = "rg-eip-shared-network-hub"
$RGSTG    = "rg-eip-stg-network-spoke"
$RGDEV    = "rg-eip-dev-network-spoke"
$VNET     = "eip-prd-vnet"
$HUB_VNET = "eip-hub-vnet"
$STG_VNET = "eip-stg-vnet"
$DEV_VNET = "eip-dev-vnet"

Write-Host "Importing PROD resources..." -ForegroundColor Cyan

# Resource Groups
terraform import azurerm_resource_group.network /subscriptions/$SUB/resourceGroups/$RG
terraform import module.storage.azurerm_resource_group.storage /subscriptions/$SUB/resourceGroups/$RGSTORAGE

# VNet
terraform import azurerm_virtual_network.vnet /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET

# Subnets
terraform import azurerm_subnet.aks_sys    /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/subnets/snet-eip-prd-aks-sys
terraform import azurerm_subnet.aks_devops /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/subnets/snet-eip-prd-aks-devops
terraform import azurerm_subnet.shared     /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/subnets/snet-eip-prd-shared
terraform import azurerm_subnet.resv       /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/subnets/snet-eip-prd-resv
terraform import azurerm_subnet.aks_app01  /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/subnets/snet-eip-prd-aks-app01

# Route Table
terraform import azurerm_route_table.spoke /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/routeTables/rt-eip-prd

# Route Table Associations (import ID = subnet ID)
terraform import azurerm_subnet_route_table_association.aks_sys    /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/subnets/snet-eip-prd-aks-sys
terraform import azurerm_subnet_route_table_association.aks_devops /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/subnets/snet-eip-prd-aks-devops
terraform import azurerm_subnet_route_table_association.aks_app01  /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/subnets/snet-eip-prd-aks-app01

# VNet Peerings — hub
terraform import azurerm_virtual_network_peering.spoke_to_hub /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/virtualNetworkPeerings/peer-prd-to-hub
terraform import azurerm_virtual_network_peering.hub_to_spoke /subscriptions/$SUB/resourceGroups/$RGHUB/providers/Microsoft.Network/virtualNetworks/$HUB_VNET/virtualNetworkPeerings/peer-hub-to-prd

# VNet Peerings — stg
terraform import azurerm_virtual_network_peering.prd_to_stg /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/virtualNetworkPeerings/peer-prd-to-stg
terraform import azurerm_virtual_network_peering.stg_to_prd /subscriptions/$SUB/resourceGroups/$RGSTG/providers/Microsoft.Network/virtualNetworks/$STG_VNET/virtualNetworkPeerings/peer-stg-to-prd

# VNet Peerings — dev
terraform import azurerm_virtual_network_peering.prd_to_dev /subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET/virtualNetworkPeerings/peer-prd-to-dev
terraform import azurerm_virtual_network_peering.dev_to_prd /subscriptions/$SUB/resourceGroups/$RGDEV/providers/Microsoft.Network/virtualNetworks/$DEV_VNET/virtualNetworkPeerings/peer-dev-to-prd

# Private DNS Zone VNet Link
terraform import azurerm_private_dns_zone_virtual_network_link.storage_blob_prd /subscriptions/$SUB/resourceGroups/$RGHUB/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net/virtualNetworkLinks/link-prd-storage-blob

# Storage Account
terraform import module.storage.azurerm_storage_account.storage /subscriptions/$SUB/resourceGroups/$RGSTORAGE/providers/Microsoft.Storage/storageAccounts/eipprdstorage001

# Private Endpoint
terraform import azurerm_private_endpoint.storage /subscriptions/$SUB/resourceGroups/$RGSTORAGE/providers/Microsoft.Network/privateEndpoints/pe-eip-storage-prd

Write-Host "PROD import complete. Run 'terraform plan' to verify." -ForegroundColor Green
