---
description: 'Terraform coding standards, naming conventions, module patterns, and security requirements for Azure infrastructure deployment in Three Horizons Accelerator'
applyTo: '**/*.tf,**/terraform/**,**/*.tfvars'
---

# Terraform Coding Standards

## Project Structure

```
terraform/
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
├── modules/
│   └── <module-name>/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── backend.tf
└── versions.tf
```

## Provider Configuration

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}
```

## Backend Configuration

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateaccount"
    container_name       = "tfstate"
    key                  = "project.tfstate"
    use_azuread_auth     = true
  }
}
```

## Naming Conventions

- Use lowercase with hyphens: `my-resource-name`
- Include environment: `project-env-resource-region`
- Use consistent abbreviations:
  - `rg` = Resource Group
  - `vnet` = Virtual Network
  - `aks` = Azure Kubernetes Service
  - `kv` = Key Vault
  - `acr` = Container Registry

## Variables

```hcl
variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  type        = string
  description = "Azure region for resources"
  default     = "eastus2"
}
```

## Outputs

```hcl
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "sensitive_data" {
  description = "Sensitive output example"
  value       = azurerm_key_vault_secret.example.value
  sensitive   = true
}
```

## Tagging Standards

```hcl
locals {
  common_tags = {
    Environment  = var.environment
    Project      = var.project_name
    Owner        = var.owner
    CostCenter   = var.cost_center
    ManagedBy    = "Terraform"
    Repository   = "three-horizons-accelerator"
  }
}
```

## Provider Selection (AzureRM vs AzAPI)

- Use `azurerm` provider for most scenarios – it offers high stability and covers the majority of Azure services
- Use `azapi` provider only for cases where you need:
  - The very latest Azure features not yet in azurerm
  - A resource not yet supported in `azurerm`
- Document the choice in code comments
- Both providers can be used together if needed, but prefer `azurerm` when in doubt

```hcl
# Example: Using azapi for preview features
resource "azapi_resource" "example" {
  type      = "Microsoft.ContainerService/managedClusters@2024-01-01"
  name      = "aks-preview-feature"
  parent_id = azurerm_resource_group.main.id
  # ... configuration for preview features
}
```

## Minimal Dependencies

- Do not introduce additional providers or modules beyond the project's scope without confirmation
- If a special provider (e.g., `random`, `tls`) is needed:
  - Add a comment to explain why
  - Ensure the team approves it
- Keep the infrastructure stack lean and avoid unnecessary complexity
- Prefer built-in Terraform functions over external providers

## Ensure Idempotency

- Write configurations that can be applied repeatedly with the same outcome
- Avoid non-idempotent actions:
  - Scripts that run on every apply
  - Resources that might conflict if created twice
- Test by doing multiple `terraform apply` runs and ensure the second run results in zero changes
- Use resource lifecycle settings for drift handling:

```hcl
resource "azurerm_kubernetes_cluster" "main" {
  # ... configuration

  lifecycle {
    ignore_changes = [
      tags["LastModified"],
      default_node_pool[0].node_count,
    ]
  }
}
```

## Security Requirements

- NEVER hardcode secrets
- ALWAYS use data sources for existing resources
- Use `sensitive = true` for sensitive outputs
- Enable soft delete and purge protection for Key Vault
- Use private endpoints for PaaS services
- Enable diagnostic settings on all resources
- Use Workload Identity instead of service principal secrets

## Module Best Practices

- Keep modules focused and reusable
- Document all inputs and outputs
- Provide sensible defaults
- Use count or for_each for conditional resources
- Include examples in README.md
- Create a module with its own variables/outputs
- Reference modules rather than duplicating code

## Documentation and Diagrams

- Maintain up-to-date documentation in README.md
- Update README.md with any new variables, outputs, or usage instructions
- Use `terraform-docs` to generate documentation automatically:

```bash
# Generate documentation
terraform-docs markdown table . > README.md
```

- Update architecture diagrams after significant infrastructure changes
- Document module dependencies and relationships

## Validate and Test Changes

- Run `terraform validate` before committing changes
- Review `terraform plan` output before applying
- Implement automated checks in CI pipeline:

```bash
# Validation commands
terraform fmt -check -recursive
terraform validate
terraform plan -var-file=environments/dev.tfvars -out=plan.tfplan

# Security scanning
tfsec .
checkov -d .
```

- Use pre-commit hooks for formatting and validation
- Consider Terratest for infrastructure testing
