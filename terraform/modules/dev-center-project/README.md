# Dev Center Project Module

Terraform module for creating Azure Dev Center Projects with Dev Box Pools for the Three Horizons Accelerator.

## Overview

This module creates Dev Center Projects and associated Dev Box Pools for team-based developer workstation provisioning. Each project can have multiple pools with different machine configurations.

## Architecture

```
Dev Center (parent)
└── Project (this module)
    ├── General Pool (8 vCPU, 32GB)
    ├── Small Pool (4 vCPU, 16GB) [optional]
    └── Performance Pool (16 vCPU, 64GB) [optional]
```

## Prerequisites

- Existing Azure Dev Center (use `dev-center` module)
- Dev Box Definitions created in the Dev Center
- Attached Network configured in the Dev Center

## Usage

```hcl
module "dev_center_project" {
  source = "../../modules/dev-center-project"

  project_name        = "platform-team"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  dev_center_id       = module.dev_center.dev_center_id
  subscription_id     = data.azurerm_client_config.current.subscription_id

  description            = "Platform Engineering Team Dev Boxes"
  team_name              = "platform"
  horizon                = "h1-foundation"
  max_dev_boxes_per_user = 2

  attached_network_name = module.dev_center.attached_network_name

  dev_box_definitions = {
    general     = "general-8c32gb-win11"
    small       = "small-4c16gb-win11"
    performance = "performance-16c64gb-win11"
  }

  enable_small_pool       = true
  enable_performance_pool = false
  local_admin_enabled     = true

  project_admin_group_ids = [azuread_group.platform_leads.object_id]
  dev_box_user_group_ids  = [azuread_group.platform_devs.object_id]

  tags = local.common_tags
}
```

## Resources Created

| Resource | Description |
|----------|-------------|
| `azurerm_dev_center_project` | Dev Center Project for the team |
| `azurerm_dev_center_project_environment_type` | Development environment type |
| `azurerm_dev_center_project_pool` | General purpose Dev Box pool |
| `azurerm_dev_center_project_pool` | Small Dev Box pool (optional) |
| `azurerm_dev_center_project_pool` | Performance Dev Box pool (optional) |
| `azurerm_role_assignment` | Project Admin role assignments |
| `azurerm_role_assignment` | Dev Box User role assignments |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project_name` | Name of the Dev Center Project | `string` | yes |
| `resource_group_name` | Resource group name | `string` | yes |
| `location` | Azure region | `string` | yes |
| `dev_center_id` | ID of the parent Dev Center | `string` | yes |
| `subscription_id` | Azure subscription ID | `string` | yes |
| `description` | Project description | `string` | no |
| `team_name` | Team name for tagging | `string` | no |
| `horizon` | Three Horizons horizon (h1/h2/h3) | `string` | no |
| `max_dev_boxes_per_user` | Maximum Dev Boxes per user | `number` | no |
| `attached_network_name` | Name of attached network | `string` | yes |
| `dev_box_definitions` | Map of pool type to definition name | `object` | yes |
| `enable_small_pool` | Enable small Dev Box pool | `bool` | no |
| `enable_performance_pool` | Enable performance Dev Box pool | `bool` | no |
| `local_admin_enabled` | Enable local admin on Dev Boxes | `bool` | no |
| `project_admin_group_ids` | Azure AD group IDs for admins | `list(string)` | no |
| `dev_box_user_group_ids` | Azure AD group IDs for users | `list(string)` | no |
| `tags` | Resource tags | `map(string)` | no |

## Outputs

| Name | Description |
|------|-------------|
| `project_id` | Dev Center Project ID |
| `project_name` | Dev Center Project name |
| `general_pool_name` | General pool name |
| `small_pool_name` | Small pool name (if enabled) |
| `performance_pool_name` | Performance pool name (if enabled) |

## Pool Configurations

| Pool | vCPUs | RAM | Storage | Use Case |
|------|-------|-----|---------|----------|
| General | 8 | 32GB | 256GB | Standard development |
| Small | 4 | 16GB | 128GB | Documentation, light work |
| Performance | 16 | 64GB | 512GB | ML/AI, large codebases |

## Auto-Stop Configuration

Dev Boxes automatically stop after disconnection to optimize costs:
- Default: 60 minutes grace period
- Configurable via `stop_on_disconnect_grace_minutes`

## Role Assignments

| Role | Purpose |
|------|---------|
| DevCenter Project Admin | Manage project settings, pools |
| DevCenter Dev Box User | Create and manage personal Dev Boxes |

## Related Modules

- [dev-center](../dev-center/README.md) - Parent Dev Center infrastructure
- [networking](../networking/README.md) - VNet and subnet configuration
- [security](../security/README.md) - Key Vault and identities
