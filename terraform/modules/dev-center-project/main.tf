# =============================================================================
# THREE HORIZONS ACCELERATOR - DEV CENTER PROJECT MODULE
# =============================================================================
#
# Terraform module for creating Dev Center Projects with Dev Box Pools.
# Each project represents a team or application with its own pools.
#
# Resources created:
#   - Dev Center Project
#   - Dev Box Pools (per environment)
#   - Project Environment Types
#   - Role Assignments
#
# Reference:
#   - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dev_center_project
#   - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dev_center_project_pool
#
# NOTE: Terraform and provider versions defined in versions.tf
# =============================================================================

# =============================================================================
# DEV CENTER PROJECT
# =============================================================================

resource "azurerm_dev_center_project" "main" {
  name                = var.project_name
  resource_group_name = var.resource_group_name
  location            = var.location
  dev_center_id       = var.dev_center_id
  description         = var.description
  
  maximum_dev_boxes_per_user = var.max_dev_boxes_per_user

  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, {
    project = var.project_name
    team    = var.team_name
    horizon = var.horizon
  })
}

# =============================================================================
# PROJECT ENVIRONMENT TYPES
# =============================================================================

resource "azurerm_dev_center_project_environment_type" "dev" {
  name                 = "development"
  location             = var.location
  dev_center_project_id = azurerm_dev_center_project.main.id
  deployment_target_id = "/subscriptions/${var.subscription_id}"

  identity {
    type = "SystemAssigned"
  }

  # Azure built-in Contributor role GUID
  creator_role_assignment_roles = [
    "b24988ac-6180-42a0-ab88-20f7382dd24c",
  ]

  tags = var.tags
}

# =============================================================================
# DEV BOX POOLS
# =============================================================================

# General purpose pool (available for all projects)
resource "azurerm_dev_center_project_pool" "general" {
  name                         = "${var.project_name}-general-pool"
  location                     = var.location
  dev_center_project_id        = azurerm_dev_center_project.main.id
  dev_box_definition_name      = var.dev_box_definitions.general
  dev_center_attached_network_name = var.attached_network_name
  local_administrator_enabled  = var.local_admin_enabled

  stop_on_disconnect_grace_period_minutes = var.stop_on_disconnect_grace_minutes

  tags = merge(var.tags, {
    pool = "general"
    size = "medium"
  })
}

# Small pool (for documentation, light development)
resource "azurerm_dev_center_project_pool" "small" {
  count = var.enable_small_pool ? 1 : 0

  name                         = "${var.project_name}-small-pool"
  location                     = var.location
  dev_center_project_id        = azurerm_dev_center_project.main.id
  dev_box_definition_name      = var.dev_box_definitions.small
  dev_center_attached_network_name = var.attached_network_name
  local_administrator_enabled  = var.local_admin_enabled

  stop_on_disconnect_grace_period_minutes = var.stop_on_disconnect_grace_minutes

  tags = merge(var.tags, {
    pool = "small"
    size = "small"
  })
}

# Performance pool (for ML/AI, large codebases)
resource "azurerm_dev_center_project_pool" "performance" {
  count = var.enable_performance_pool && var.dev_box_definitions.performance != null ? 1 : 0

  name                         = "${var.project_name}-performance-pool"
  location                     = var.location
  dev_center_project_id        = azurerm_dev_center_project.main.id
  dev_box_definition_name      = var.dev_box_definitions.performance
  dev_center_attached_network_name = var.attached_network_name
  local_administrator_enabled  = var.local_admin_enabled

  stop_on_disconnect_grace_period_minutes = var.stop_on_disconnect_grace_minutes

  tags = merge(var.tags, {
    pool = "performance"
    size = "large"
  })
}

# =============================================================================
# ROLE ASSIGNMENTS
# =============================================================================

# Project Admin role assignment (for team leads)
resource "azurerm_role_assignment" "project_admin" {
  for_each = toset(var.project_admin_group_ids)

  scope                = azurerm_dev_center_project.main.id
  role_definition_name = "DevCenter Project Admin"
  principal_id         = each.value
}

# Dev Box User role assignment (for developers)
resource "azurerm_role_assignment" "dev_box_user" {
  for_each = toset(var.dev_box_user_group_ids)

  scope                = azurerm_dev_center_project.main.id
  role_definition_name = "DevCenter Dev Box User"
  principal_id         = each.value
}
