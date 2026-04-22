# ─────────────────────────────────────────────
# modules/aks/main.tf
# AKS clusters — one per spoke environment
# ─────────────────────────────────────────────

resource "azurerm_user_assigned_identity" "aks" {
  for_each            = var.spoke_subnet_ids
  name                = "id-aks-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_kubernetes_cluster" "spoke" {
  for_each            = var.spoke_subnet_ids
  name                = "aks-${each.key}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-${each.key}"
  kubernetes_version  = var.kubernetes_version
  tags                = merge(var.tags, { environment = each.key })

  default_node_pool {
    name           = "system"
    node_count     = var.aks_node_counts[each.key]
    vm_size        = var.aks_vm_sizes[each.key]
    vnet_subnet_id = each.value

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks[each.key].id]
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "userDefinedRouting"
  }

  lifecycle {
    ignore_changes = [default_node_pool[0].node_count]
  }
}
