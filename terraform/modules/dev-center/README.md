# Azure Dev Center (Microsoft Dev Box) Module

This module deploys Azure Dev Center for providing managed Windows developer workstations.

## Overview

Azure Dev Box provides self-service, high-performance cloud workstations for developers. This module creates the foundational Dev Center infrastructure that projects can use to provision Dev Box pools.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure Dev Center                         │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────────┐ │
│  │ Dev Box          │  │ Network          │  │ Gallery       │ │
│  │ Definitions      │  │ Connection       │  │ (Custom Imgs) │ │
│  │ - General 8c/32g │  │ - VNet/Subnet    │  │               │ │
│  │ - Small 4c/16g   │  │ - AAD Join       │  │               │ │
│  │ - Perf 16c/64g   │  │                  │  │               │ │
│  └──────────────────┘  └──────────────────┘  └───────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                          Projects                               │
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────────┐ │
│  │ Project A        │  │ Project B        │  │ Project C     │ │
│  │ - General Pool   │  │ - General Pool   │  │ - Perf Pool   │ │
│  │ - Small Pool     │  │ - Perf Pool      │  │               │ │
│  └──────────────────┘  └──────────────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Dev Center Setup

```hcl
module "dev_center" {
  source = "./modules/dev-center"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  naming = {
    dev_center = "dc-threehorizons-dev"
  }
  
  subnet_id        = module.networking.dev_center_subnet_id
  domain_join_type = "AzureADJoin"
  
  log_analytics_workspace_id = module.observability.log_analytics_workspace_id
  
  tags = local.common_tags
}
```

### Create Project with Pools

```hcl
module "dev_center_project_platform" {
  source = "./modules/dev-center-project"

  project_name        = "platform-engineering"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  dev_center_id       = module.dev_center.dev_center_id
  subscription_id     = data.azurerm_subscription.current.subscription_id
  attached_network_name = module.dev_center.attached_network_name
  
  dev_box_definitions = {
    general     = module.dev_center.dev_box_definitions.general.name
    small       = module.dev_center.dev_box_definitions.small.name
    performance = try(module.dev_center.dev_box_definitions.performance.name, null)
  }
  
  description        = "Platform Engineering team Dev Boxes"
  team_name          = "platform-engineering"
  horizon            = "h1-foundation"
  max_dev_boxes_per_user = 3
  
  enable_small_pool       = true
  enable_performance_pool = true
  local_admin_enabled     = true
  
  project_admin_group_ids = [data.azuread_group.platform_admins.object_id]
  dev_box_user_group_ids  = [data.azuread_group.developers.object_id]
  
  tags = local.common_tags
}
```

## Dev Box Definitions

| Definition | vCPU | RAM | Storage | Use Case |
|------------|------|-----|---------|----------|
| general-8c32gb-win11 | 8 | 32GB | 256GB SSD | General development |
| small-4c16gb-win11 | 4 | 16GB | 128GB SSD | Documentation, light work |
| performance-16c64gb-win11 | 16 | 64GB | 512GB SSD | ML/AI, large codebases |

## Comparison: Dev Box vs Codespaces vs Devbox

| Feature | Microsoft Dev Box | GitHub Codespaces | Jetify Devbox |
|---------|------------------|-------------------|---------------|
| **OS** | Windows 11 | Linux (container) | Local (Nix) |
| **Interface** | Full desktop/RDP | VS Code browser/local | Terminal/local IDE |
| **Persistence** | Full VM | Container | Local files |
| **Cold Start** | 15-30 min | 30-60 sec | Instant |
| **Cost Model** | Hourly (running) | Hourly (active) | Free |
| **GPU Support** | Yes | Limited | Local GPU |
| **Offline** | No | No | Yes |
| **Use Case** | Windows-only dev | Cross-platform | Local dev |

## Developer Access

Developers access Dev Boxes through:

1. **Dev Portal**: https://devportal.microsoft.com
   - Self-service creation and management
   - Start/stop/delete Dev Boxes
   
2. **VS Code Remote**:
   - Install Remote - SSH extension
   - Connect directly from local VS Code
   
3. **Remote Desktop**:
   - Full Windows desktop experience
   - Best for Windows-specific development

## Integration with RHDH

Dev Box projects can be integrated with RHDH (Red Hat Developer Hub) Golden Paths:

```yaml
# In template.yaml
parameters:
  - title: Development Environment
    properties:
      devEnvironment:
        title: Development Environment
        type: string
        default: codespaces
        enum:
          - codespaces
          - devbox
          - dev-box
        enumNames:
          - GitHub Codespaces (Linux containers)
          - Jetify Devbox (Local Nix)
          - Microsoft Dev Box (Windows workstations)
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| resource_group_name | Resource group name | string | - | yes |
| location | Azure region | string | - | yes |
| naming | Naming convention object | object | - | yes |
| subnet_id | Subnet ID for network connection | string | - | yes |
| domain_join_type | AAD or Hybrid join | string | "AzureADJoin" | no |
| enable_high_performance_definitions | Enable 16c/64g definition | bool | false | no |
| custom_image_gallery_id | Compute Gallery for custom images | string | null | no |
| github_catalog_config | GitHub catalog for customization tasks | object | null | no |
| log_analytics_workspace_id | LAW for diagnostics | string | null | no |

## Outputs

| Name | Description |
|------|-------------|
| dev_center_id | ID of the Dev Center |
| dev_center_name | Name of the Dev Center |
| dev_center_uri | URI for API access |
| network_connection_id | Network connection ID |
| attached_network_name | Attached network name for pools |
| dev_box_definitions | Map of available definitions |
| developer_portal_url | Dev Portal URL |

## Related Modules

- `dev-center-project` - Create projects with pools
- `networking` - VNet/subnet configuration
- `security` - RBAC and identity
