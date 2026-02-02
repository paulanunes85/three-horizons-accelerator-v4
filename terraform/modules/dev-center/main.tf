# =============================================================================
# THREE HORIZONS ACCELERATOR - AZURE DEV CENTER MODULE
# =============================================================================
#
# Terraform module for Azure Dev Center (Microsoft Dev Box)
# Provides Windows-based developer workstations as a managed service.
#
# Resources created:
#   - Dev Center
#   - Dev Box Definitions (machine configurations)
#   - Network Connection
#   - Attached Networks
#   - Gallery integration for custom images
#
# Reference:
#   - https://learn.microsoft.com/en-us/azure/dev-box/
#   - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dev_center
#
# NOTE: Terraform and provider versions defined in versions.tf
# =============================================================================

# =============================================================================
# DEV CENTER
# =============================================================================

resource "azurerm_dev_center" "main" {
  name                = var.naming.dev_center
  resource_group_name = var.resource_group_name
  location            = var.location

  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, {
    component = "dev-center"
    horizon   = "h1-foundation"
  })
}

# =============================================================================
# NETWORK CONNECTION
# =============================================================================

resource "azurerm_dev_center_network_connection" "main" {
  name                = "${var.naming.dev_center}-netcon"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_id
  domain_join_type    = var.domain_join_type

  tags = var.tags
}

# Attach network connection to Dev Center
resource "azurerm_dev_center_attached_network" "main" {
  name                  = "${var.naming.dev_center}-attached"
  dev_center_id         = azurerm_dev_center.main.id
  network_connection_id = azurerm_dev_center_network_connection.main.id
}

# =============================================================================
# DEV BOX DEFINITIONS
# =============================================================================

# General Development workstation (8 vCPU, 32GB RAM)
resource "azurerm_dev_center_dev_box_definition" "general_8c32gb" {
  name          = "general-8c32gb-win11"
  location      = var.location
  dev_center_id = azurerm_dev_center.main.id

  image_reference_id = "${azurerm_dev_center.main.id}/galleries/default/images/microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2"
  sku_name           = "general_i_8c32gb256ssd_v2"

  tags = merge(var.tags, {
    definition = "general"
    size       = "medium"
  })
}

# High-performance workstation (16 vCPU, 64GB RAM) for ML/AI
resource "azurerm_dev_center_dev_box_definition" "performance_16c64gb" {
  count = var.enable_high_performance_definitions ? 1 : 0

  name          = "performance-16c64gb-win11"
  location      = var.location
  dev_center_id = azurerm_dev_center.main.id

  image_reference_id = "${azurerm_dev_center.main.id}/galleries/default/images/microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2"
  sku_name           = "general_i_16c64gb512ssd_v2"

  tags = merge(var.tags, {
    definition = "performance"
    size       = "large"
  })
}

# Small workstation (4 vCPU, 16GB RAM) for documentation/light work
resource "azurerm_dev_center_dev_box_definition" "small_4c16gb" {
  name          = "small-4c16gb-win11"
  location      = var.location
  dev_center_id = azurerm_dev_center.main.id

  image_reference_id = "${azurerm_dev_center.main.id}/galleries/default/images/microsoftwindowsdesktop_windows-ent-cpc_win11-23h2-ent-cpc-os"
  sku_name           = "general_i_4c16gb128ssd_v2"

  tags = merge(var.tags, {
    definition = "small"
    size       = "small"
  })
}

# =============================================================================
# CUSTOM IMAGE GALLERY (OPTIONAL)
# =============================================================================

resource "azurerm_dev_center_gallery" "custom" {
  count = var.custom_image_gallery_id != null ? 1 : 0

  dev_center_id         = azurerm_dev_center.main.id
  shared_gallery_id     = var.custom_image_gallery_id
  name                  = "custom-gallery"
}

# =============================================================================
# ENVIRONMENT TYPES
# =============================================================================

resource "azurerm_dev_center_environment_type" "dev" {
  name          = "development"
  dev_center_id = azurerm_dev_center.main.id

  tags = var.tags
}

resource "azurerm_dev_center_environment_type" "staging" {
  name          = "staging"
  dev_center_id = azurerm_dev_center.main.id

  tags = var.tags
}

resource "azurerm_dev_center_environment_type" "prod" {
  name          = "production"
  dev_center_id = azurerm_dev_center.main.id

  tags = var.tags
}

# =============================================================================
# CATALOG (FOR CUSTOMIZATION TASKS)
# =============================================================================

resource "azurerm_dev_center_catalog" "github" {
  count = var.github_catalog_config != null ? 1 : 0

  resource_group_name = var.resource_group_name
  dev_center_id       = azurerm_dev_center.main.id
  name                = "github-catalog"

  catalog_github {
    uri               = var.github_catalog_config.uri
    branch            = var.github_catalog_config.branch
    path              = var.github_catalog_config.path
    key_vault_key_url = var.github_catalog_config.key_vault_secret_url
  }
}

# =============================================================================
# ROLE ASSIGNMENTS
# =============================================================================

# Grant Dev Center identity permissions to Key Vault (for catalog secrets)
resource "azurerm_role_assignment" "dev_center_keyvault" {
  count = var.key_vault_id != null ? 1 : 0

  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_dev_center.main.identity[0].principal_id
}

# Grant Dev Center identity permissions to Azure Compute Gallery
resource "azurerm_role_assignment" "dev_center_gallery" {
  count = var.custom_image_gallery_id != null ? 1 : 0

  scope                = var.custom_image_gallery_id
  role_definition_name = "Reader"
  principal_id         = azurerm_dev_center.main.identity[0].principal_id
}

# =============================================================================
# DIAGNOSTIC SETTINGS
# =============================================================================

resource "azurerm_monitor_diagnostic_setting" "dev_center" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.naming.dev_center}-diag"
  target_resource_id         = azurerm_dev_center.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
