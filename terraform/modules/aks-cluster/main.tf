# =============================================================================
# THREE HORIZONS ACCELERATOR - AKS CLUSTER MODULE
# =============================================================================
# 
# This module creates a production-ready Azure Kubernetes Service cluster
# optimized for the Three Horizons Platform.
#
# Features:
#   - Multi-zone deployment for high availability
#   - System and user node pools separation
#   - Azure CNI with Overlay networking
#   - Workload Identity for secure pod authentication
#   - Azure Key Vault integration
#   - Container Insights for monitoring
#   - Azure Policy for governance
#
# =============================================================================

# NOTE: Terraform block is in versions.tf
# NOTE: Variables are defined in variables.tf


# =============================================================================
# LOCALS
# =============================================================================

locals {
  cluster_name = "aks-${var.customer_name}-${var.environment}"
  dns_prefix   = "${var.customer_name}-${var.environment}"

  default_tags = merge(var.tags, {
    Component = "AKS"
    Module    = "three-horizons-accelerator"
  })
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "azurerm_client_config" "current" {}

# =============================================================================
# AKS CLUSTER
# =============================================================================

resource "azurerm_kubernetes_cluster" "main" {
  name                = local.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = local.dns_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  # ==========================================================================
  # SYSTEM NODE POOL
  # ==========================================================================
  default_node_pool {
    name           = var.system_node_pool.name
    vm_size        = var.system_node_pool.vm_size
    node_count     = var.system_node_pool.node_count
    zones          = var.system_node_pool.zones
    vnet_subnet_id = var.vnet_subnet_id

    # Pod subnet for Azure CNI Overlay
    pod_subnet_id = var.pod_subnet_id

    # System pool settings
    only_critical_addons_enabled = true

    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
    }

    # Upgrade settings
    upgrade_settings {
      max_surge = "33%"
    }

    tags = local.default_tags
  }

  # ==========================================================================
  # IDENTITY
  # ==========================================================================
  identity {
    type = "SystemAssigned"
  }

  # ==========================================================================
  # NETWORK PROFILE
  # ==========================================================================
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"

    # Service CIDR (internal Kubernetes services)
    service_cidr   = "10.0.32.0/24"
    dns_service_ip = "10.0.32.10"
  }

  # ==========================================================================
  # OIDC & WORKLOAD IDENTITY
  # ==========================================================================
  oidc_issuer_enabled       = var.workload_identity
  workload_identity_enabled = var.workload_identity

  # ==========================================================================
  # AZURE AD INTEGRATION
  # ==========================================================================
  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  # ==========================================================================
  # KEY VAULT SECRETS PROVIDER
  # ==========================================================================
  dynamic "key_vault_secrets_provider" {
    for_each = var.addons.azure_keyvault_secrets ? [1] : []
    content {
      secret_rotation_enabled  = true
      secret_rotation_interval = "2m"
    }
  }

  # ==========================================================================
  # AZURE POLICY
  # ==========================================================================
  azure_policy_enabled = var.addons.azure_policy

  # ==========================================================================
  # CONTAINER INSIGHTS (OMS AGENT)
  # ==========================================================================
  dynamic "oms_agent" {
    for_each = var.addons.oms_agent && var.log_analytics_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_id
    }
  }

  # ==========================================================================
  # AUTO-SCALER PROFILE
  # ==========================================================================
  auto_scaler_profile {
    balance_similar_node_groups      = true
    expander                         = "random"
    max_graceful_termination_sec     = 600
    max_node_provisioning_time       = "15m"
    max_unready_nodes                = 3
    max_unready_percentage           = 45
    new_pod_scale_up_delay           = "10s"
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_delay_after_failure   = "3m"
    scan_interval                    = "10s"
    scale_down_unneeded              = "10m"
    scale_down_unready               = "20m"
    scale_down_utilization_threshold = 0.5
    empty_bulk_delete_max            = 10
    skip_nodes_with_local_storage    = false
    skip_nodes_with_system_pods      = true
  }

  # ==========================================================================
  # MAINTENANCE WINDOW
  # ==========================================================================
  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [0, 1, 2, 3, 4]
    }
  }

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "00:00"
    utc_offset  = "-03:00"
  }

  maintenance_window_node_os {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "04:00"
    utc_offset  = "-03:00"
  }

  tags = local.default_tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      kubernetes_version
    ]
  }
}

# =============================================================================
# USER NODE POOLS
# =============================================================================

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = { for np in var.user_node_pools : np.name => np }

  name                  = each.value.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = each.value.vm_size
  zones                 = each.value.zones
  vnet_subnet_id        = var.vnet_subnet_id
  pod_subnet_id         = var.pod_subnet_id

  # Auto-scaling
  enable_auto_scaling = true
  min_count           = each.value.min_count
  max_count           = each.value.max_count

  # Labels and taints
  node_labels = merge(each.value.labels, {
    "environment" = var.environment
  })

  node_taints = each.value.taints

  # Upgrade settings
  upgrade_settings {
    max_surge = "33%"
  }

  tags = local.default_tags

  lifecycle {
    ignore_changes = [node_count]
  }
}

# =============================================================================
# RBAC - ACR PULL PERMISSION
# =============================================================================

resource "azurerm_role_assignment" "acr_pull" {
  count = var.acr_id != null ? 1 : 0

  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}

# =============================================================================
# RBAC - KEY VAULT ACCESS
# =============================================================================

resource "azurerm_role_assignment" "keyvault_secrets" {
  count = var.key_vault_id != null ? 1 : 0

  principal_id                     = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id
  role_definition_name             = "Key Vault Secrets User"
  scope                            = var.key_vault_id
  skip_service_principal_aad_check = true
}

# =============================================================================
# DIAGNOSTIC SETTINGS
# =============================================================================

resource "azurerm_monitor_diagnostic_setting" "aks" {
  count = var.log_analytics_id != null ? 1 : 0

  name                       = "aks-diagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.main.id
  log_analytics_workspace_id = var.log_analytics_id

  # Control plane logs
  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "guard"
  }

  # Metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================
