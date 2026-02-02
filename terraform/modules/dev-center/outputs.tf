# =============================================================================
# THREE HORIZONS ACCELERATOR - DEV CENTER OUTPUTS
# =============================================================================

output "dev_center_id" {
  description = "ID of the Dev Center"
  value       = azurerm_dev_center.main.id
}

output "dev_center_name" {
  description = "Name of the Dev Center"
  value       = azurerm_dev_center.main.name
}

output "dev_center_uri" {
  description = "URI of the Dev Center"
  value       = azurerm_dev_center.main.dev_center_uri
}

output "dev_center_identity_principal_id" {
  description = "Principal ID of the Dev Center managed identity"
  value       = azurerm_dev_center.main.identity[0].principal_id
}

output "network_connection_id" {
  description = "ID of the network connection"
  value       = azurerm_dev_center_network_connection.main.id
}

output "attached_network_name" {
  description = "Name of the attached network for use in project pools"
  value       = azurerm_dev_center_attached_network.main.name
}

output "dev_box_definitions" {
  description = "Map of Dev Box definition names to their details"
  value = {
    general = {
      name     = azurerm_dev_center_dev_box_definition.general_8c32gb.name
      sku      = "general_i_8c32gb256ssd_v2"
      cpu      = 8
      memory   = 32
      use_case = "General development"
    }
    small = {
      name     = azurerm_dev_center_dev_box_definition.small_4c16gb.name
      sku      = "general_i_4c16gb128ssd_v2"
      cpu      = 4
      memory   = 16
      use_case = "Documentation, light development"
    }
    performance = var.enable_high_performance_definitions ? {
      name     = azurerm_dev_center_dev_box_definition.performance_16c64gb[0].name
      sku      = "general_i_16c64gb512ssd_v2"
      cpu      = 16
      memory   = 64
      use_case = "ML/AI, large codebases"
    } : null
  }
}

output "environment_types" {
  description = "Map of environment type names"
  value = {
    development = azurerm_dev_center_environment_type.dev.name
    staging     = azurerm_dev_center_environment_type.staging.name
    production  = azurerm_dev_center_environment_type.prod.name
  }
}

output "developer_portal_url" {
  description = "URL for developers to access Dev Box portal"
  value       = "https://devportal.microsoft.com"
}
