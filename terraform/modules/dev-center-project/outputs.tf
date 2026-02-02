# =============================================================================
# THREE HORIZONS ACCELERATOR - DEV CENTER PROJECT OUTPUTS
# =============================================================================

output "project_id" {
  description = "ID of the Dev Center project"
  value       = azurerm_dev_center_project.main.id
}

output "project_name" {
  description = "Name of the project"
  value       = azurerm_dev_center_project.main.name
}

output "project_uri" {
  description = "Dev Center URI for this project"
  value       = azurerm_dev_center_project.main.dev_center_uri
}

output "pools" {
  description = "Map of pool names and their configurations"
  value = {
    general = {
      name     = azurerm_dev_center_project_pool.general.name
      id       = azurerm_dev_center_project_pool.general.id
      size     = "8 vCPU, 32GB RAM"
      use_case = "General development"
    }
    small = var.enable_small_pool ? {
      name     = azurerm_dev_center_project_pool.small[0].name
      id       = azurerm_dev_center_project_pool.small[0].id
      size     = "4 vCPU, 16GB RAM"
      use_case = "Documentation, light development"
    } : null
    performance = var.enable_performance_pool && var.dev_box_definitions.performance != null ? {
      name     = azurerm_dev_center_project_pool.performance[0].name
      id       = azurerm_dev_center_project_pool.performance[0].id
      size     = "16 vCPU, 64GB RAM"
      use_case = "ML/AI, large codebases"
    } : null
  }
}

output "developer_portal_project_url" {
  description = "Direct URL for developers to access this project's Dev Boxes"
  value       = "https://devportal.microsoft.com/projects/${var.project_name}"
}

output "vscode_connection_instructions" {
  description = "Instructions for connecting VS Code to Dev Box"
  value       = <<-EOT
    ## Connect VS Code to Dev Box
    
    1. Open VS Code
    2. Install "Remote - SSH" extension
    3. Go to https://devportal.microsoft.com
    4. Select project: ${var.project_name}
    5. Create or start your Dev Box
    6. Click "Open in VS Code"
    
    Alternatively, use Remote Desktop (RDP) for full Windows experience.
  EOT
}
