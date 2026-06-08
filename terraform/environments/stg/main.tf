terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "terraform_remote_state" "shared" {
  backend = "local"
  config = {
    path = "${path.module}/../shared/terraform.tfstate"
  }
}

# ── Shared resources (already provisioned, referenced as data sources) ─────────

# Shared nonprod ACR — acreipnonprd5shr in rg-eip-nonprod-acr
data "azurerm_container_registry" "shared" {
  name                = var.acr_name
  resource_group_name = var.acr_resource_group_name
}

# Private DNS zones live in the hub RG — only add VNet links for stg, never recreate zones
data "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.dns_zone_resource_group
}

data "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.dns_zone_resource_group
}

data "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.dns_zone_resource_group
}

data "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.dns_zone_resource_group
}

# ── Network resources (spoke) ──────────────────────────────────────────────────

resource "azurerm_resource_group" "network" {
  name     = "rg-${var.prefix}-${var.environment}-network-spoke"
  location = var.location
  tags     = { environment = var.environment, project = var.project }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-${var.environment}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  tags                = { environment = var.environment, project = var.project }
}

resource "azurerm_subnet" "aks_sys" {
  name                 = "snet-${var.prefix}-${var.environment}-aks-sys"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 1)]
}

resource "azurerm_subnet" "aks_app" {
  name                 = "snet-${var.prefix}-${var.environment}-aks-app"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 2)]
}

# PE network policies disabled so private endpoint NICs bypass the route table
# (otherwise PE traffic would hairpin through the firewall)
resource "azurerm_subnet" "shared" {
  name                              = "snet-${var.prefix}-${var.environment}-shared"
  resource_group_name               = azurerm_resource_group.network.name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = [cidrsubnet(var.vnet_cidr, 8, 3)]
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_subnet" "resv" {
  name                 = "snet-${var.prefix}-${var.environment}-resv"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 4)]
}

# ── AKS ───────────────────────────────────────────────────────────────────────

module "aks" {
  source             = "../../shared/modules/aks"
  prefix             = var.prefix
  project            = var.project
  environment        = var.environment
  location           = var.location
  rg_name_override   = "rg-${var.prefix}-${var.environment}-aks"
  aks_cluster_name   = var.aks_cluster_name
  aks_dns_prefix     = var.aks_dns_prefix
  aks_node_count     = var.aks_node_count
  aks_vm_size        = var.aks_vm_size
  kubernetes_version = var.kubernetes_version
  app_node_pool_name = var.app_node_pool_name
  app_node_count     = var.app_node_count
  app_vm_size        = var.app_vm_size

  subnet_aks_system_id = azurerm_subnet.aks_sys.id
  subnet_aks_app_id    = azurerm_subnet.aks_app.id

  enable_key_vault_secrets_provider = true
}

# ── Storage ───────────────────────────────────────────────────────────────────

module "storage" {
  source                   = "../../shared/modules/storage"
  prefix                   = var.prefix
  project                  = var.project
  environment              = var.environment
  location                 = var.location
  rg_name_override         = "rg-${var.prefix}-${var.environment}-storage"
  storage_account_tier     = var.storage_account_tier
  storage_replication_type = var.storage_replication_type
}

# ── Role assignments ───────────────────────────────────────────────────────────

# Kubelet identity pulls images from the shared nonprod ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = data.azurerm_container_registry.shared.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
}

# Cluster identity manages load balancers and NICs in the spoke VNet
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_virtual_network.vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = module.aks.aks_identity_principal_id
}

# Kubelet identity reads/writes blobs (Storage Blob Data Contributor)
resource "azurerm_role_assignment" "aks_storage_blob_contributor" {
  scope                = module.storage.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.aks.kubelet_identity_object_id
}

# CSI secret store driver gets Key Vault Secrets Officer on the shared Key Vault
# Set var.key_vault_id once the Key Vault resource ID is known
resource "azurerm_role_assignment" "csi_key_vault_secrets_officer" {
  count                = var.key_vault_id != null ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = module.aks.key_vault_secrets_provider_object_id
}

# ── Hub-spoke peering ──────────────────────────────────────────────────────────

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-${var.environment}-to-hub"
  resource_group_name       = azurerm_resource_group.network.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = data.terraform_remote_state.shared.outputs.hub_vnet_id
  allow_forwarded_traffic   = true
  use_remote_gateways       = false
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-${var.environment}"
  resource_group_name       = data.terraform_remote_state.shared.outputs.hub_resource_group_name
  virtual_network_name      = data.terraform_remote_state.shared.outputs.hub_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
}

# ── Route table: force spoke traffic through hub firewall ─────────────────────

resource "azurerm_route_table" "spoke" {
  name                          = "rt-${var.prefix}-${var.environment}"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.network.name
  bgp_route_propagation_enabled = false

  route {
    name                   = "to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = data.terraform_remote_state.shared.outputs.firewall_private_ip
  }
}

resource "azurerm_subnet_route_table_association" "aks_sys" {
  subnet_id      = azurerm_subnet.aks_sys.id
  route_table_id = azurerm_route_table.spoke.id
}

resource "azurerm_subnet_route_table_association" "aks_app" {
  subnet_id      = azurerm_subnet.aks_app.id
  route_table_id = azurerm_route_table.spoke.id
}

# ── Private DNS Zone VNet links ────────────────────────────────────────────────
# Zones already exist in var.dns_zone_resource_group (rg-eip-shared-network-hub).
# Only add a spoke VNet link for stg — hub link was created when dev was provisioned.

resource "azurerm_private_dns_zone_virtual_network_link" "acr_stg" {
  name                  = "link-${var.environment}-acr"
  resource_group_name   = var.dns_zone_resource_group
  private_dns_zone_name = data.azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob_stg" {
  name                  = "link-${var.environment}-storage-blob"
  resource_group_name   = var.dns_zone_resource_group
  private_dns_zone_name = data.azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_stg" {
  name                  = "link-${var.environment}-sql"
  resource_group_name   = var.dns_zone_resource_group
  private_dns_zone_name = data.azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres_stg" {
  name                  = "link-${var.environment}-postgres"
  resource_group_name   = var.dns_zone_resource_group
  private_dns_zone_name = data.azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

# ── Private Endpoints ──────────────────────────────────────────────────────────
# Each PE is placed in the same RG as its backing service (matching dev pattern).

# pe-eip-acr-stg → rg-eip-nonprod-acr (same RG as the shared ACR)
resource "azurerm_private_endpoint" "acr" {
  name                = "pe-${var.prefix}-acr-${var.environment}"
  location            = var.location
  resource_group_name = var.acr_resource_group_name
  subnet_id           = azurerm_subnet.shared.id

  private_service_connection {
    name                           = "psc-${var.prefix}-acr-${var.environment}"
    private_connection_resource_id = data.azurerm_container_registry.shared.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "dns-group-acr"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.acr.id]
  }
}

# pe-eip-storage-stg → rg-eip-stg-storage (same RG as the storage account)
resource "azurerm_private_endpoint" "storage" {
  name                = "pe-${var.prefix}-storage-${var.environment}"
  location            = var.location
  resource_group_name = module.storage.resource_group_name
  subnet_id           = azurerm_subnet.shared.id

  private_service_connection {
    name                           = "psc-${var.prefix}-storage-${var.environment}"
    private_connection_resource_id = module.storage.storage_account_id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "dns-group-storage-blob"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.storage_blob.id]
  }
}

# pe-eip-postgres-stg → var.postgres_resource_group_name (set once stg PostgreSQL is created)
resource "azurerm_private_endpoint" "postgres" {
  count               = var.postgres_server_id != null ? 1 : 0
  name                = "pe-${var.prefix}-postgres-${var.environment}"
  location            = var.location
  resource_group_name = var.postgres_resource_group_name
  subnet_id           = azurerm_subnet.shared.id

  private_service_connection {
    name                           = "psc-${var.prefix}-postgres-${var.environment}"
    private_connection_resource_id = var.postgres_server_id
    is_manual_connection           = false
    subresource_names              = ["postgresqlServer"]
  }

  private_dns_zone_group {
    name                 = "dns-group-postgres"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.postgres.id]
  }
}

# pe-eip-sql-stg → var.sql_resource_group_name (rg-eip-nonprod-sql)
resource "azurerm_private_endpoint" "sql" {
  count               = var.sql_server_id != null ? 1 : 0
  name                = "pe-${var.prefix}-sql-${var.environment}"
  location            = var.location
  resource_group_name = var.sql_resource_group_name
  subnet_id           = azurerm_subnet.shared.id

  private_service_connection {
    name                           = "psc-${var.prefix}-sql-${var.environment}"
    private_connection_resource_id = var.sql_server_id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "dns-group-sql"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.sql.id]
  }
}
