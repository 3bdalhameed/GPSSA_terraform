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

# Read hub outputs from the shared environment's state
data "terraform_remote_state" "shared" {
  backend = "local"
  config = {
    path = "${path.module}/../shared/terraform.tfstate"
  }
}

module "network" {
  source      = "../../shared/modules/network"
  prefix      = var.prefix
  project     = var.project
  environment = var.environment
  location    = var.location
  vnet_cidr   = var.vnet_cidr
}

module "aks" {
  source             = "../../shared/modules/aks"
  prefix             = var.prefix
  project            = var.project
  environment        = var.environment
  location           = var.location
  aks_cluster_name   = var.aks_cluster_name
  aks_dns_prefix     = var.aks_dns_prefix
  aks_node_count     = var.aks_node_count
  aks_vm_size        = var.aks_vm_size
  kubernetes_version = var.kubernetes_version
  app_node_pool_name = var.app_node_pool_name
  app_node_count     = var.app_node_count
  app_vm_size        = var.app_vm_size

  subnet_aks_system_id = module.network.subnet_aks_system_id
  subnet_aks_app_id    = module.network.subnet_aks_app_id
}

module "acr" {
  source            = "../../shared/modules/acr"
  prefix            = var.prefix
  project           = var.project
  environment       = var.environment
  location          = var.location
  acr_sku           = var.acr_sku
  acr_admin_enabled = var.acr_admin_enabled
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = module.acr.acr_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.aks_identity_principal_id
}

module "storage" {
  source                   = "../../shared/modules/storage"
  prefix                   = var.prefix
  project                  = var.project
  environment              = var.environment
  location                 = var.location
  storage_account_tier     = var.storage_account_tier
  storage_replication_type = var.storage_replication_type
}

# ── Hub-spoke peering ──────────────────────────────────────────────────────────

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-${var.environment}-to-hub"
  resource_group_name       = module.network.resource_group_name
  virtual_network_name      = module.network.vnet_name
  remote_virtual_network_id = data.terraform_remote_state.shared.outputs.hub_vnet_id
  allow_forwarded_traffic   = true
  use_remote_gateways       = var.enable_gateway_transit
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-${var.environment}"
  resource_group_name       = data.terraform_remote_state.shared.outputs.hub_resource_group_name
  virtual_network_name      = data.terraform_remote_state.shared.outputs.hub_vnet_name
  remote_virtual_network_id = module.network.vnet_id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = var.enable_gateway_transit
}

# ── Route table: force all spoke traffic through the firewall ─────────────────

resource "azurerm_route_table" "spoke" {
  name                          = "rt-${var.prefix}-${var.environment}"
  location                      = var.location
  resource_group_name           = module.network.resource_group_name
  bgp_route_propagation_enabled = false

  route {
    name                   = "to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = data.terraform_remote_state.shared.outputs.firewall_private_ip
  }
}

resource "azurerm_subnet_route_table_association" "aks_system" {
  subnet_id      = module.network.subnet_aks_system_id
  route_table_id = azurerm_route_table.spoke.id
}

resource "azurerm_subnet_route_table_association" "aks_app" {
  subnet_id      = module.network.subnet_aks_app_id
  route_table_id = azurerm_route_table.spoke.id
}
