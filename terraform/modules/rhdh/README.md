# RHDH Module

Red Hat Developer Hub (Backstage) infrastructure on AKS.

## Features

- RHDH Helm deployment
- PostgreSQL database integration
- Azure Blob Storage for TechDocs
- Workload Identity configuration
- GitHub App integration
- Azure AD authentication
- ArgoCD plugin integration
- Kubernetes plugin
- Search with PostgreSQL

## Usage

```hcl
module "rhdh" {
  source = "./modules/rhdh"

  customer_name       = "threehorizons"
  environment         = "prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  namespace           = "rhdh"

  base_url     = "https://backstage.example.com"
  replicas     = 2
  rhdh_version = "1.2.0"

  # AKS integration
  aks_oidc_issuer_url = module.aks.oidc_issuer_url
  subnet_id           = module.networking.services_subnet_id
  key_vault_name      = module.security.key_vault_name

  # Database
  postgresql_host     = module.databases.postgresql_fqdn
  postgresql_username = "backstage"
  postgresql_password = var.postgresql_password
  postgresql_database = "backstage"

  # GitHub App
  github_org                = "my-org"
  github_app_id             = var.github_app_id
  github_app_client_id      = var.github_app_client_id
  github_app_client_secret  = var.github_app_client_secret
  github_app_private_key    = var.github_app_private_key
  github_app_webhook_secret = var.github_app_webhook_secret

  # Azure AD
  azure_tenant_id     = data.azurerm_client_config.current.tenant_id
  azure_client_id     = var.azure_client_id
  azure_client_secret = var.azure_client_secret

  # ArgoCD
  argocd_url        = module.argocd.argocd_url
  argocd_auth_token = var.argocd_auth_token

  # Features
  enable_techdocs          = true
  enable_kubernetes_plugin = true
  enable_search            = true

  tags = module.naming.tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |
| kubernetes | ~> 2.23 |
| helm | ~> 2.11 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| customer_name | Customer name | `string` | n/a | yes |
| environment | Environment | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| namespace | Kubernetes namespace | `string` | `"rhdh"` | no |
| base_url | RHDH base URL | `string` | n/a | yes |
| replicas | Number of replicas | `number` | `2` | no |
| rhdh_version | RHDH Helm chart version | `string` | `"1.2.0"` | no |
| aks_oidc_issuer_url | AKS OIDC issuer URL | `string` | n/a | yes |
| subnet_id | Subnet ID for storage | `string` | n/a | yes |
| key_vault_name | Key Vault name | `string` | n/a | yes |
| postgresql_host | PostgreSQL host | `string` | n/a | yes |
| postgresql_username | PostgreSQL username | `string` | n/a | yes |
| postgresql_password | PostgreSQL password | `string` | n/a | yes |
| postgresql_database | PostgreSQL database name | `string` | n/a | yes |
| github_org | GitHub organization | `string` | n/a | yes |
| github_app_id | GitHub App ID | `string` | n/a | yes |
| github_app_client_id | GitHub App client ID | `string` | n/a | yes |
| github_app_client_secret | GitHub App client secret | `string` | n/a | yes |
| github_app_private_key | GitHub App private key | `string` | n/a | yes |
| github_app_webhook_secret | GitHub App webhook secret | `string` | n/a | yes |
| azure_tenant_id | Azure AD tenant ID | `string` | n/a | yes |
| azure_client_id | Azure AD client ID | `string` | n/a | yes |
| azure_client_secret | Azure AD client secret | `string` | n/a | yes |
| argocd_url | ArgoCD URL | `string` | n/a | yes |
| argocd_auth_token | ArgoCD auth token | `string` | n/a | yes |
| enable_techdocs | Enable TechDocs | `bool` | `true` | no |
| enable_kubernetes_plugin | Enable K8s plugin | `bool` | `true` | no |
| enable_search | Enable search | `bool` | `true` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | RHDH namespace |
| base_url | RHDH base URL |
| identity_client_id | RHDH managed identity client ID |
| techdocs_storage_account | TechDocs storage account name |

## Catalog Configuration

Default catalog locations:
- `software-templates` repository for templates
- `software-catalog` repository for entities

## Plugins

Pre-configured plugins:
- **GitHub**: Source code management, scaffolder
- **Azure AD**: Authentication provider
- **ArgoCD**: Deployment tracking
- **Kubernetes**: Workload visibility
- **TechDocs**: Documentation publishing
- **Search**: Full-text search with PostgreSQL

## Workload Identity

The module configures:
1. User-assigned managed identity
2. Federated credential for RHDH service account
3. Key Vault Secrets User role
4. Storage Blob Data Contributor role (for TechDocs)
