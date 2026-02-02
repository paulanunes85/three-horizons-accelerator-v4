# =============================================================================
# THREE HORIZONS ACCELERATOR - DEV CENTER VARIABLES
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the Dev Center"
  type        = string
}

variable "naming" {
  description = "Naming convention outputs from naming module"
  type = object({
    dev_center = string
  })
}

variable "subnet_id" {
  description = "ID of the subnet for Dev Box network connection"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "domain_join_type" {
  description = "Type of domain join for Dev Boxes. Use 'AzureADJoin' for cloud-only or 'HybridAzureADJoin' for hybrid."
  type        = string
  default     = "AzureADJoin"

  validation {
    condition     = contains(["AzureADJoin", "HybridAzureADJoin"], var.domain_join_type)
    error_message = "domain_join_type must be either 'AzureADJoin' or 'HybridAzureADJoin'."
  }
}

# -----------------------------------------------------------------------------
# Dev Box Definitions
# -----------------------------------------------------------------------------

variable "enable_high_performance_definitions" {
  description = "Enable high-performance Dev Box definitions (16 vCPU, 64GB RAM)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Custom Images
# -----------------------------------------------------------------------------

variable "custom_image_gallery_id" {
  description = "ID of Azure Compute Gallery for custom images (optional)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Catalog Configuration
# -----------------------------------------------------------------------------

variable "github_catalog_config" {
  description = "GitHub catalog configuration for Dev Box customization tasks"
  type = object({
    uri                  = string
    branch               = string
    path                 = string
    key_vault_secret_url = string
  })
  default = null
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------

variable "log_analytics_workspace_id" {
  description = "ID of Log Analytics workspace for diagnostics"
  type        = string
  default     = null
}

variable "key_vault_id" {
  description = "ID of Key Vault for catalog secrets"
  type        = string
  default     = null
}
