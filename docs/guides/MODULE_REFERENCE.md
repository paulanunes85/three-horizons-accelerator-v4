# Three Horizons Accelerator - Module Reference

> **Version:** 4.0.0
> **Last Updated:** December 2025

---

## Table of Contents

1. [Module Overview](#1-module-overview)
2. [H1 Foundation Modules](#2-h1-foundation-modules)
3. [H2 Enhancement Modules](#3-h2-enhancement-modules)
4. [H3 Innovation Modules](#4-h3-innovation-modules)
5. [Cross-Cutting Modules](#5-cross-cutting-modules)
6. [Module Dependencies](#6-module-dependencies)
7. [Usage Examples](#7-usage-examples)

---

## 1. Module Overview

### Module Directory Structure

```
terraform/modules/
├── naming/              # Naming conventions
├── networking/          # VNet, subnets, NSGs
├── aks-cluster/         # Kubernetes cluster
├── container-registry/  # Azure Container Registry
├── databases/           # PostgreSQL, Redis
├── security/            # Key Vault, identities
├── defender/            # Defender for Cloud
├── purview/             # Microsoft Purview
├── observability/       # Azure Monitor
├── argocd/              # ArgoCD setup
├── external-secrets/    # External Secrets Operator
├── github-runners/      # Self-hosted runners
├── cost-management/     # Budgets and alerts
├── disaster-recovery/   # DR configuration
├── ai-foundry/          # Azure OpenAI
└── rhdh/                # Red Hat Developer Hub
```

### Standard Module Structure

Each module follows this pattern:

```
module-name/
├── main.tf          # Resource definitions
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── versions.tf      # Provider requirements
└── README.md        # Module documentation
```

---

## 2. H1 Foundation Modules

### 2.1 Naming Module

**Path:** `terraform/modules/naming`
**Purpose:** Generate consistent resource names following Azure naming conventions.

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `customer_name` | string | yes | - | Customer identifier (max 12 chars) |
| `environment` | string | yes | - | Environment (dev/staging/prod) |
| `region` | string | yes | - | Azure region |
| `project` | string | no | "platform" | Project name |

#### Outputs

| Output | Description |
|--------|-------------|
| `resource_group_name` | Generated resource group name |
| `aks_cluster_name` | Generated AKS cluster name |
| `storage_account_name` | Generated storage account name (24 char max) |
| `container_registry_name` | Generated ACR name (no hyphens) |
| `key_vault_name` | Generated Key Vault name (24 char max) |
| `region_short` | 3-letter region code |

#### Usage

```hcl
module "naming" {
  source = "./modules/naming"

  customer_name = "contoso"
  environment   = "dev"
  region        = "brazilsouth"
  project       = "platform"
}

# Use outputs
resource "azurerm_resource_group" "main" {
  name     = module.naming.resource_group_name
  location = var.location
}
```

---

### 2.2 Networking Module

**Path:** `terraform/modules/networking`
**Purpose:** Create VNet, subnets, NSGs, and private DNS zones.

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `customer_name` | string | yes | - | Customer identifier |
| `environment` | string | yes | - | Environment |
| `location` | string | yes | - | Azure region |
| `resource_group_name` | string | yes | - | Resource group name |
| `vnet_cidr` | string | yes | - | VNet address space |
| `subnet_config` | object | no | See below | Subnet CIDRs |
| `enable_bastion` | bool | no | false | Enable Azure Bastion |
| `enable_app_gateway` | bool | no | false | Enable App Gateway subnet |
| `dns_zone_name` | string | yes | - | DNS zone name |
| `create_dns_zone` | bool | no | false | Create public DNS zone |
| `tags` | map(string) | no | {} | Resource tags |

#### Subnet Config Object

```hcl
subnet_config = {
  aks_nodes_cidr         = "10.0.0.0/22"
  aks_pods_cidr          = "10.0.16.0/20"
  private_endpoints_cidr = "10.0.4.0/24"
  bastion_cidr           = "10.0.5.0/26"
  app_gateway_cidr       = "10.0.6.0/24"
}
```

#### Outputs

| Output | Description |
|--------|-------------|
| `vnet_id` | Virtual network resource ID |
| `vnet_name` | Virtual network name |
| `aks_nodes_subnet_id` | AKS nodes subnet ID |
| `aks_pods_subnet_id` | AKS pods subnet ID |
| `private_endpoints_subnet_id` | Private endpoints subnet ID |
| `bastion_subnet_id` | Bastion subnet ID |
| `nsg_aks_nodes_id` | AKS nodes NSG ID |
| `private_dns_zone_ids` | Map of private DNS zone IDs |

#### Usage

```hcl
module "networking" {
  source = "./modules/networking"

  customer_name       = "contoso"
  environment         = "dev"
  location            = "brazilsouth"
  resource_group_name = azurerm_resource_group.main.name
  vnet_cidr           = "10.0.0.0/16"
  dns_zone_name       = "contoso.example.com"
  enable_bastion      = true
  create_dns_zone     = false

  tags = var.tags
}
```

---

### 2.3 AKS Cluster Module

**Path:** `terraform/modules/aks-cluster`
**Purpose:** Deploy Azure Kubernetes Service cluster.

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `resource_group_name` | string | yes | - | Resource group name |
| `location` | string | yes | - | Azure region |
| `customer_name` | string | yes | - | Customer identifier |
| `environment` | string | yes | - | Environment |
| `kubernetes_version` | string | no | "1.29" | Kubernetes version |
| `sku_tier` | string | no | "Standard" | AKS SKU (Free/Standard/Premium) |
| `vnet_subnet_id` | string | yes | - | Subnet ID for AKS nodes |
| `pod_subnet_id` | string | no | null | Subnet ID for pods (CNI Overlay) |
| `system_node_pool` | object | no | See below | System node pool config |
| `user_node_pools` | list(object) | no | [] | User node pool configs |
| `acr_id` | string | no | null | ACR ID for pull permissions |
| `key_vault_id` | string | no | null | Key Vault ID for secrets |
| `log_analytics_id` | string | no | null | Log Analytics workspace ID |
| `addons` | object | no | See below | AKS addon configuration |
| `workload_identity` | bool | no | true | Enable workload identity |
| `tags` | map(string) | no | {} | Resource tags |

#### System Node Pool Object

```hcl
system_node_pool = {
  name       = "system"
  vm_size    = "Standard_D4s_v5"
  node_count = 3
  zones      = ["1", "2", "3"]
}
```

#### User Node Pool Object

```hcl
user_node_pools = [
  {
    name      = "user"
    vm_size   = "Standard_D8s_v5"
    min_count = 3
    max_count = 10
    zones     = ["1", "2", "3"]
    labels    = { workload = "general" }
    taints    = []
  },
  {
    name      = "gpu"
    vm_size   = "Standard_NC6s_v3"
    min_count = 0
    max_count = 5
    zones     = ["1"]
    labels    = { workload = "gpu", accelerator = "nvidia" }
    taints    = ["gpu=true:NoSchedule"]
  }
]
```

#### Addons Object

```hcl
addons = {
  azure_policy           = true
  azure_keyvault_secrets = true
  oms_agent              = true
}
```

#### Outputs

| Output | Description |
|--------|-------------|
| `cluster_id` | AKS cluster resource ID |
| `cluster_name` | AKS cluster name |
| `cluster_fqdn` | AKS cluster FQDN |
| `kube_config` | Kubeconfig for cluster access |
| `kubelet_identity_id` | Kubelet managed identity ID |
| `oidc_issuer_url` | OIDC issuer URL for workload identity |
| `node_resource_group` | Auto-created node resource group |

#### Usage

```hcl
module "aks" {
  source = "./modules/aks-cluster"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  customer_name       = var.customer_name
  environment         = var.environment
  kubernetes_version  = "1.29"
  sku_tier            = "Standard"
  vnet_subnet_id      = module.networking.aks_nodes_subnet_id
  pod_subnet_id       = module.networking.aks_pods_subnet_id
  acr_id              = module.acr.acr_id
  key_vault_id        = module.security.key_vault_id
  workload_identity   = true

  system_node_pool = {
    name       = "system"
    vm_size    = "Standard_D4s_v5"
    node_count = 3
    zones      = ["1", "2", "3"]
  }

  user_node_pools = var.user_node_pools
  addons          = var.aks_addons
  tags            = var.tags
}
```

---

### 2.4 Container Registry Module

**Path:** `terraform/modules/container-registry`
**Purpose:** Deploy Azure Container Registry.

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `name` | string | yes | - | ACR name (alphanumeric only) |
| `resource_group_name` | string | yes | - | Resource group name |
| `location` | string | yes | - | Azure region |
| `sku` | string | no | "Premium" | ACR SKU |
| `admin_enabled` | bool | no | false | Enable admin user |
| `public_network_access_enabled` | bool | no | false | Enable public access |
| `zone_redundancy_enabled` | bool | no | true | Enable zone redundancy |
| `georeplications` | list(object) | no | [] | Geo-replication config |
| `private_endpoint_subnet_id` | string | no | null | Subnet for private endpoint |
| `private_dns_zone_id` | string | no | null | Private DNS zone ID |
| `tags` | map(string) | no | {} | Resource tags |

#### Outputs

| Output | Description |
|--------|-------------|
| `acr_id` | ACR resource ID |
| `acr_name` | ACR name |
| `login_server` | ACR login server URL |
| `admin_username` | Admin username (if enabled) |
| `admin_password` | Admin password (if enabled) |

#### Usage

```hcl
module "acr" {
  source = "./modules/container-registry"

  name                = module.naming.container_registry_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = "Premium"

  public_network_access_enabled = false
  private_endpoint_subnet_id    = module.networking.private_endpoints_subnet_id
  private_dns_zone_id           = module.networking.private_dns_zone_ids["acr"]

  tags = var.tags
}
```

---

### 2.5 Security Module

**Path:** `terraform/modules/security`
**Purpose:** Deploy Key Vault and managed identities.

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `customer_name` | string | yes | - | Customer identifier |
| `environment` | string | yes | - | Environment |
| `resource_group_name` | string | yes | - | Resource group name |
| `location` | string | yes | - | Azure region |
| `key_vault_name` | string | yes | - | Key Vault name |
| `tenant_id` | string | yes | - | Azure AD tenant ID |
| `enable_rbac_authorization` | bool | no | true | Use RBAC for Key Vault |
| `private_endpoint_subnet_id` | string | no | null | Subnet for private endpoint |
| `private_dns_zone_id` | string | no | null | Private DNS zone ID |
| `create_workload_identity` | bool | no | true | Create workload identity |
| `aks_oidc_issuer_url` | string | no | null | AKS OIDC issuer for federation |
| `tags` | map(string) | no | {} | Resource tags |

#### Outputs

| Output | Description |
|--------|-------------|
| `key_vault_id` | Key Vault resource ID |
| `key_vault_name` | Key Vault name |
| `key_vault_uri` | Key Vault URI |
| `aks_identity_id` | AKS managed identity ID |
| `aks_identity_principal_id` | AKS identity principal ID |
| `workload_identity_id` | Workload identity ID |
| `workload_identity_client_id` | Workload identity client ID |

#### Usage

```hcl
module "security" {
  source = "./modules/security"

  customer_name       = var.customer_name
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  key_vault_name      = module.naming.key_vault_name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  enable_rbac_authorization     = true
  private_endpoint_subnet_id    = module.networking.private_endpoints_subnet_id
  private_dns_zone_id           = module.networking.private_dns_zone_ids["keyvault"]
  create_workload_identity      = true
  aks_oidc_issuer_url           = module.aks.oidc_issuer_url

  tags = var.tags
}
```

---

### 2.6 Databases Module

**Path:** `terraform/modules/databases`
**Purpose:** Deploy PostgreSQL Flexible Server and Redis Cache.

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `customer_name` | string | yes | - | Customer identifier |
| `environment` | string | yes | - | Environment |
| `resource_group_name` | string | yes | - | Resource group name |
| `location` | string | yes | - | Azure region |
| `enable_postgresql` | bool | no | true | Enable PostgreSQL |
| `postgresql_config` | object | no | See below | PostgreSQL configuration |
| `enable_redis` | bool | no | false | Enable Redis |
| `redis_config` | object | no | See below | Redis configuration |
| `private_endpoint_subnet_id` | string | no | null | Subnet for private endpoints |
| `private_dns_zone_ids` | map(string) | no | {} | Private DNS zone IDs |
| `key_vault_id` | string | no | null | Key Vault for storing credentials |
| `tags` | map(string) | no | {} | Resource tags |

#### PostgreSQL Config Object

```hcl
postgresql_config = {
  sku_name               = "GP_Standard_D2s_v3"
  storage_mb             = 32768
  version                = "15"
  backup_retention_days  = 7
  geo_redundant_backup   = false
  high_availability_mode = "ZoneRedundant"
  databases              = ["app_db"]
}
```

#### Outputs

| Output | Description |
|--------|-------------|
| `postgresql_server_id` | PostgreSQL server ID |
| `postgresql_server_name` | PostgreSQL server name |
| `postgresql_fqdn` | PostgreSQL FQDN |
| `redis_id` | Redis Cache ID |
| `redis_hostname` | Redis hostname |

---

### 2.7 Defender Module

**Path:** `terraform/modules/defender`
**Purpose:** Configure Microsoft Defender for Cloud.

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `subscription_id` | string | yes | - | Azure subscription ID |
| `resource_group_name` | string | yes | - | Resource group name |
| `location` | string | yes | - | Azure region |
| `enable_container_plan` | bool | no | true | Enable Defender for Containers |
| `enable_keyvault_plan` | bool | no | true | Enable Defender for Key Vault |
| `enable_storage_plan` | bool | no | true | Enable Defender for Storage |
| `enable_database_plan` | bool | no | true | Enable Defender for Databases |
| `security_contact_email` | string | yes | - | Security contact email |
| `alert_notifications` | bool | no | true | Enable alert notifications |
| `tags` | map(string) | no | {} | Resource tags |

#### Outputs

| Output | Description |
|--------|-------------|
| `defender_plans_enabled` | List of enabled Defender plans |

---

### 2.8 Purview Module

**Path:** `terraform/modules/purview`
**Purpose:** Deploy Microsoft Purview for data governance.

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `name` | string | yes | - | Purview account name |
| `resource_group_name` | string | yes | - | Resource group name |
| `location` | string | yes | - | Azure region |
| `managed_resource_group_name` | string | no | null | Managed RG name |
| `public_network_enabled` | bool | no | false | Enable public access |
| `private_endpoint_subnet_id` | string | no | null | Subnet for private endpoint |
| `enable_latam_classifications` | bool | no | true | Enable LATAM data types |
| `tags` | map(string) | no | {} | Resource tags |

#### LATAM Classifications

When `enable_latam_classifications = true`, creates custom classifications for:
- CPF (Brazil)
- CNPJ (Brazil)
- RUT (Chile)
- RFC (Mexico)
- DNI (Argentina)

---

## 3. H2 Enhancement Modules

### 3.1 ArgoCD Module

**Path:** `terraform/modules/argocd`
**Purpose:** Configure ArgoCD for GitOps deployments.

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `namespace` | string | no | "argocd" | Kubernetes namespace |
| `version` | string | no | "2.9.0" | ArgoCD version |
| `admin_password` | string | no | null | Admin password (auto-generated if null) |
| `github_org` | string | yes | - | GitHub organization |
| `github_client_id` | string | no | null | GitHub OAuth client ID |
| `github_client_secret` | string | no | null | GitHub OAuth secret |
| `enable_notifications` | bool | no | true | Enable notifications |
| `notification_webhooks` | map(string) | no | {} | Webhook URLs |

#### Outputs

| Output | Description |
|--------|-------------|
| `argocd_server_url` | ArgoCD server URL |
| `admin_password` | Admin password (sensitive) |
| `namespace` | ArgoCD namespace |

---

### 3.2 External Secrets Module

**Path:** `terraform/modules/external-secrets`
**Purpose:** Deploy External Secrets Operator.

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `namespace` | string | no | "external-secrets" | Kubernetes namespace |
| `version` | string | no | "0.9.0" | ESO Helm chart version |
| `key_vault_name` | string | yes | - | Azure Key Vault name |
| `key_vault_url` | string | yes | - | Key Vault URL |
| `tenant_id` | string | yes | - | Azure AD tenant ID |
| `workload_identity_client_id` | string | yes | - | Workload identity client ID |

#### Outputs

| Output | Description |
|--------|-------------|
| `namespace` | ESO namespace |
| `cluster_secret_store_name` | ClusterSecretStore name |

---

### 3.3 Observability Module

**Path:** `terraform/modules/observability`
**Purpose:** Deploy Azure Monitor and configure Prometheus/Grafana.

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `customer_name` | string | yes | - | Customer identifier |
| `environment` | string | yes | - | Environment |
| `resource_group_name` | string | yes | - | Resource group name |
| `location` | string | yes | - | Azure region |
| `aks_cluster_id` | string | yes | - | AKS cluster ID |
| `enable_azure_monitor` | bool | no | true | Enable Azure Monitor |
| `enable_prometheus` | bool | no | true | Enable Prometheus |
| `enable_grafana` | bool | no | true | Enable Grafana |
| `log_retention_days` | number | no | 30 | Log retention period |
| `tags` | map(string) | no | {} | Resource tags |

#### Outputs

| Output | Description |
|--------|-------------|
| `log_analytics_workspace_id` | Log Analytics workspace ID |
| `prometheus_endpoint` | Prometheus endpoint URL |
| `grafana_endpoint` | Grafana endpoint URL |

---

### 3.4 GitHub Runners Module

**Path:** `terraform/modules/github-runners`
**Purpose:** Deploy self-hosted GitHub Actions runners on AKS.

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `namespace` | string | no | "github-runners" | Kubernetes namespace |
| `github_org` | string | yes | - | GitHub organization |
| `github_app_id` | string | yes | - | GitHub App ID |
| `github_app_installation_id` | string | yes | - | App installation ID |
| `github_app_private_key` | string | yes | - | App private key |
| `runner_scale_set_name` | string | no | "arc-runners" | Scale set name |
| `min_runners` | number | no | 1 | Minimum runners |
| `max_runners` | number | no | 10 | Maximum runners |
| `runner_image` | string | no | "ghcr.io/actions/runner:latest" | Runner image |

---

## 4. H3 Innovation Modules

### 4.1 AI Foundry Module

**Path:** `terraform/modules/ai-foundry`
**Purpose:** Deploy Azure OpenAI and AI services.

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `name` | string | yes | - | Cognitive Services account name |
| `resource_group_name` | string | yes | - | Resource group name |
| `location` | string | yes | - | Azure region (use eastus2 for full models) |
| `sku` | string | no | "S0" | Pricing SKU |
| `public_network_access_enabled` | bool | no | false | Enable public access |
| `private_endpoint_subnet_id` | string | no | null | Subnet for private endpoint |
| `private_dns_zone_id` | string | no | null | Private DNS zone ID |
| `model_deployments` | list(object) | no | See below | Model deployments |
| `key_vault_id` | string | no | null | Key Vault for storing API key |
| `tags` | map(string) | no | {} | Resource tags |

#### Model Deployments Object

```hcl
model_deployments = [
  {
    name          = "gpt-4o"
    model_name    = "gpt-4o"
    model_version = "2024-05-13"
    capacity      = 10
  },
  {
    name          = "gpt-4o-mini"
    model_name    = "gpt-4o-mini"
    model_version = "2024-07-18"
    capacity      = 20
  },
  {
    name          = "text-embedding-3-large"
    model_name    = "text-embedding-3-large"
    model_version = "1"
    capacity      = 50
  }
]
```

#### Outputs

| Output | Description |
|--------|-------------|
| `cognitive_account_id` | Cognitive Services account ID |
| `endpoint` | API endpoint URL |
| `primary_key` | Primary API key (sensitive) |
| `deployment_ids` | Map of deployment names to IDs |

---

## 5. Cross-Cutting Modules

### 5.1 Cost Management Module

**Path:** `terraform/modules/cost-management`
**Purpose:** Configure budgets and cost alerts.

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `resource_group_name` | string | yes | - | Resource group name |
| `subscription_id` | string | yes | - | Subscription ID |
| `budget_amount` | number | yes | - | Monthly budget in USD |
| `alert_thresholds` | list(number) | no | [50, 75, 90, 100] | Alert percentages |
| `alert_emails` | list(string) | yes | - | Alert email addresses |
| `tags` | map(string) | no | {} | Resource tags |

---

### 5.2 Disaster Recovery Module

**Path:** `terraform/modules/disaster-recovery`
**Purpose:** Configure DR resources and replication.

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `customer_name` | string | yes | - | Customer identifier |
| `environment` | string | yes | - | Environment |
| `primary_location` | string | yes | - | Primary region |
| `secondary_location` | string | yes | - | DR region |
| `resource_group_name` | string | yes | - | Resource group name |
| `enable_aks_dr` | bool | no | false | Enable AKS DR cluster |
| `enable_database_replication` | bool | no | true | Enable DB replication |
| `enable_storage_replication` | bool | no | true | Enable storage GRS |
| `tags` | map(string) | no | {} | Resource tags |

---

## 6. Module Dependencies

### Dependency Graph

```
                    ┌──────────┐
                    │  naming  │
                    └────┬─────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
    ┌─────────┐    ┌──────────┐    ┌──────────┐
    │networking│    │ security │    │ databases│
    └────┬────┘    └────┬─────┘    └────┬─────┘
         │              │               │
         └──────┬───────┴───────┬───────┘
                │               │
                ▼               ▼
         ┌───────────┐   ┌──────────────┐
         │aks-cluster│   │container-reg │
         └─────┬─────┘   └──────────────┘
               │
    ┌──────────┼──────────┬──────────┐
    │          │          │          │
    ▼          ▼          ▼          ▼
┌───────┐ ┌────────┐ ┌─────────┐ ┌──────┐
│argocd │ │external│ │observ-  │ │github│
│       │ │secrets │ │ability  │ │runner│
└───────┘ └────────┘ └─────────┘ └──────┘
```

### Required Order

```hcl
# 1. First: Naming (no dependencies)
module "naming" { ... }

# 2. Second: Networking (depends on naming outputs)
module "networking" {
  depends_on = [module.naming]
}

# 3. Third: Security (depends on networking for private endpoints)
module "security" {
  depends_on = [module.networking]
}

# 4. Fourth: AKS (depends on networking and security)
module "aks" {
  depends_on = [module.networking, module.security]
}

# 5. Fifth: H2 modules (depends on AKS)
module "argocd" {
  depends_on = [module.aks]
}
```

---

## 7. Usage Examples

### Minimal Deployment (H1 Only)

```hcl
module "naming" {
  source        = "./modules/naming"
  customer_name = "minimal"
  environment   = "dev"
  region        = "brazilsouth"
}

module "networking" {
  source              = "./modules/networking"
  customer_name       = var.customer_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  vnet_cidr           = "10.0.0.0/16"
  dns_zone_name       = "minimal.internal"
}

module "aks" {
  source              = "./modules/aks-cluster"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  customer_name       = var.customer_name
  environment         = var.environment
  vnet_subnet_id      = module.networking.aks_nodes_subnet_id
}
```

### Full Platform Deployment

```hcl
# See terraform/main.tf for complete example
module "naming"           { ... }
module "networking"       { ... }
module "security"         { ... }
module "aks"              { ... }
module "acr"              { ... }
module "databases"        { ... }
module "defender"         { ... }
module "purview"          { ... }
module "observability"    { ... }
module "argocd"           { ... }
module "external_secrets" { ... }
module "github_runners"   { ... }
module "cost_management"  { ... }
module "ai_foundry"       { ... }  # Optional H3
```

---

**Document Version:** 1.0.0
**Last Updated:** December 2025
**Maintainer:** Platform Engineering Team
