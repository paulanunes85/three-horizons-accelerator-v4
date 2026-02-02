# =============================================================================
# THREE HORIZONS ACCELERATOR - DEV CENTER PROJECT VARIABLES
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the Dev Center project"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_.]{2,62}$", var.project_name))
    error_message = "Project name must be 3-63 characters, start with alphanumeric, and contain only alphanumeric, hyphens, underscores, or periods."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "dev_center_id" {
  description = "ID of the parent Dev Center"
  type        = string
}

variable "subscription_id" {
  description = "Subscription ID for deployment target"
  type        = string
}

variable "attached_network_name" {
  description = "Name of the attached network from Dev Center"
  type        = string
}

variable "dev_box_definitions" {
  description = "Map of Dev Box definition names from Dev Center"
  type = object({
    general     = string
    small       = string
    performance = optional(string)
  })
}

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------

variable "description" {
  description = "Description of the project"
  type        = string
  default     = ""
}

variable "team_name" {
  description = "Name of the team that owns this project"
  type        = string
  default     = "platform-engineering"
}

variable "horizon" {
  description = "Three Horizons classification (h1-foundation, h2-enhancement, h3-innovation)"
  type        = string
  default     = "h1-foundation"

  validation {
    condition     = contains(["h1-foundation", "h2-enhancement", "h3-innovation"], var.horizon)
    error_message = "horizon must be one of: h1-foundation, h2-enhancement, h3-innovation."
  }
}

variable "max_dev_boxes_per_user" {
  description = "Maximum number of Dev Boxes a single user can create"
  type        = number
  default     = 3

  validation {
    condition     = var.max_dev_boxes_per_user >= 1 && var.max_dev_boxes_per_user <= 10
    error_message = "max_dev_boxes_per_user must be between 1 and 10."
  }
}

# -----------------------------------------------------------------------------
# Pool Configuration
# -----------------------------------------------------------------------------

variable "enable_small_pool" {
  description = "Enable small Dev Box pool (4 vCPU, 16GB)"
  type        = bool
  default     = true
}

variable "enable_performance_pool" {
  description = "Enable performance Dev Box pool (16 vCPU, 64GB)"
  type        = bool
  default     = false
}

variable "local_admin_enabled" {
  description = "Allow local administrator access on Dev Boxes"
  type        = bool
  default     = true
}

variable "stop_on_disconnect_grace_minutes" {
  description = "Grace period in minutes before stopping Dev Box on disconnect"
  type        = number
  default     = 60

  validation {
    condition     = var.stop_on_disconnect_grace_minutes >= 15 && var.stop_on_disconnect_grace_minutes <= 480
    error_message = "stop_on_disconnect_grace_minutes must be between 15 and 480."
  }
}

# -----------------------------------------------------------------------------
# Access Control
# -----------------------------------------------------------------------------

variable "project_admin_group_ids" {
  description = "List of Entra ID group object IDs for project admin access"
  type        = list(string)
  default     = []
}

variable "dev_box_user_group_ids" {
  description = "List of Entra ID group object IDs for Dev Box user access"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
