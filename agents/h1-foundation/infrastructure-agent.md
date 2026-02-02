---
name: "Infrastructure Agent"
version: "2.0.0"
horizon: "H1"
status: "stable"
last_updated: "2026-02-02"
skills:
  - terraform-cli
  - azure-cli
  - kubectl-cli
  - validation-scripts
dependencies:
  - naming
  - aks-cluster
  - networking
  - security
  - container-registry
---

# Infrastructure Agent

## Overview

The Infrastructure Agent provisions and manages core Azure infrastructure for the Three Horizons Platform.

## Skills Integration

This agent leverages the following skills from `.github/skills/`:

| Skill | Path | Usage |
|-------|------|-------|
| **terraform-cli** | `.github/skills/terraform-cli/` | Terraform operations (init, plan, apply, validate) |
| **azure-cli** | `.github/skills/azure-cli/` | Azure resource management, AKS, ACR, Key Vault operations |
| **kubectl-cli** | `.github/skills/kubectl-cli/` | Kubernetes cluster validation and health checks |
| **validation-scripts** | `.github/skills/validation-scripts/` | Reusable validation patterns for infrastructure |

## Explicit Consent Required

**IMPORTANT**: This agent will request explicit user confirmation before executing:

- ✋ `terraform apply` - Infrastructure deployment
- ✋ `az resource delete` - Resource deletion
- ✋ `kubectl delete` - Kubernetes resource removal
- ✋ Any state-modifying command that impacts production resources

**Default behavior**: When in doubt, **no action** is taken until explicit "yes" is received.

Example prompts:
```
Should I proceed with terraform apply to create 47 resources in subscription 'prod-subscription'? (yes/no)
Should I proceed with deleting resource group 'rg-threehorizons-prd-brs'? (yes/no)
```

## Responsibilities

- Deploy Azure Kubernetes Service (AKS) clusters
- Configure networking (VNet, subnets, NSGs)
- Provision Azure Container Registry (ACR)
- Setup Azure Key Vault
- Configure Managed Identities
- Apply Azure Policy assignments

## Integration Points

### Terraform Modules

| Module | Path | Purpose |
|--------|------|---------|
| **naming** | `terraform/modules/naming/` | CAF-compliant resource naming |
| aks-cluster | `terraform/modules/aks-cluster/` | Kubernetes cluster |
| networking | `terraform/modules/networking/` | Network infrastructure |
| security | `terraform/modules/security/` | Key Vault, identities |
| container-registry | `terraform/modules/container-registry/` | Container registry |

### Scripts

| Script | Purpose |
|--------|---------|
| `scripts/validate-cli-prerequisites.sh` | Verify required CLIs |
| `scripts/validate-naming.sh` | Validate resource names |
| `scripts/validate-config.sh` | Validate configuration |

### Issue Template

- **Template**: `.github/ISSUE_TEMPLATE/infrastructure.yml`
- **Labels**: `agent:infrastructure`, `horizon:h1`

## Terraform Best Practices

### Quality Checks

Before deploying infrastructure, this agent runs comprehensive quality checks:

```bash
# 1. Format code
terraform fmt -recursive

# 2. Validate syntax
terraform validate

# 3. Security scanning
tfsec . --minimum-severity MEDIUM

# 4. Static analysis
tflint --config .tflint.hcl

# 5. Generate documentation
terraform-docs markdown table . --output-file README.md
```

### Dependency Management

**Prefer implicit dependencies over explicit `depends_on`:**

```hcl
# ✅ Good - Implicit dependency
resource "azurerm_kubernetes_cluster" "main" {
  name                = module.naming.aks_cluster
  resource_group_name = azurerm_resource_group.main.name  # Implicit dependency
  # ...
}

# ❌ Bad - Unnecessary explicit dependency
resource "azurerm_kubernetes_cluster" "main" {
  name                = module.naming.aks_cluster
  resource_group_name = azurerm_resource_group.main.name
  depends_on          = [azurerm_resource_group.main]  # Redundant!
}Validation

### Pre-flight Checks

Before deployment, this agent performs comprehensive validation using `.github/skills/validation-scripts/`:

```bash
# 1. Validate Azure resources
./.github/skills/validation-scripts/validate-azure-resources.sh \
  --subscription-id $SUBSCRIPTION_ID \
  --resource-group rg-threehorizons-prd-brs

# 2. Validate Kubernetes cluster (post-deployment)
./.github/skills/validation-scripts/validate-k8s-cluster.sh \
  --cluster-name aks-threehorizons-prd-brs

# 3. Validate Terraform state
./.github/skills/validation-scripts/validate-terraform-state.sh \
  --state-file terraform.tfstate

# 4. Detect drift
./.github/skills/validation-scripts/detect-drift.sh \
  --working-dir ./terraform
```

### Post-deployment Validation

| Check | Command | Expected Result |
|-------|---------|-----------------|
| AKS cluster health | `kubectl get nodes` | All nodes Ready |
| System pods running | `kubectl get pods -n kube-system` | All Running |
| ACR connectivity | `az acr check-health --name $ACR_NAME` | Healthy |
| Key Vault access | `az keyvault show --name $KV_NAME` | Success |
| Workload Identity | `kubectl get azureidentity -A` | Identities created |

### Health Checks

```bash
# Comprehensive health check
gh issue comment $ISSUE_NUMBER --body "
## Infrastructure Health Check

### AKS Cluster
\`\`\`
$(kubectl get nodes -o wide)
\`\`\`

### System Workloads
\`\`\`
$(kubectl get pods -n kube-system --field-selector=status.phase!=Running)
\`\`\`

### Azure Resources
- ✅ Resource Group: $(az group show -n rg-threehorizons-prd-brs -o table)
- ✅ AKS: $(az aks show -g rg-threehorizons-prd-brs -n aks-threehorizons-prd-brs --query provisioningState -o tsv)
- ✅ ACR: $(az acr show -n crthreehorizonsprdbrs --query provisioningState -o tsv)
- ✅ Key Vault: $(az keyvault show -n kv-threehorizons-prd-brs --query properties.provisioningState -o tsv)
"
```

## Workflow

```yaml
# Triggered by: infrastructure.yml issue
# Dependencies: None (foundation)

steps:
  - name: Validate Prerequisites
    run: ./scripts/validate-cli-prerequisites.sh
    
  - name: Validate Naming
    run: ./scripts/validate-naming.sh --all $PROJECT $ENV $REGION
  
  - name: Initialize Terraform
    run: |
      cd terraform
      terraform init
  
  - name: Terraform Quality Checks
    run: |
      terraform fmt -check -recursive
      terraform validate
      tfsec . --minimum-severity MEDIUM
      tflint --config .tflint.hcl
  
  - name: Plan Infrastructure
    run: terraform plan -out=tfplan
  
  - name: Review Plan
    run: terraform show -json tfplan | jq '.resource_changes[] | select(.change.actions[] | contains("create"))'
  
  - name: Request User Confirmation
    prompt: "Should I proceed with terraform apply to create resources? (yes/no)"
    
  - name: Apply Infrastructure
    if: user_confirmed == "yes"
    run: terraform apply tfplan
  
  - name: Post-deployment Validation
    run: |
      ./.github/skills/validation-scripts/validate-azure-resources.sh
      ./.github/skills/validation-scripts/validate-k8s-cluster.sh
  
  - name: Output Summary
    run: |
      terraform output -json > infrastructure-summary.json
      gh issue comment $ISSUE_NUMBER --body "$(cat infrastructure-summary.json | jq -r '.')"

| Azure Resource | AVM Module | Status |
|----------------|------------|--------|
| AKS Cluster | `Azure/avm-res-containerservice-managedcluster/azurerm` | ✅ Recommended |
| Container Registry | `Azure/avm-res-containerregistry-registry/azurerm` | ✅ Recommended |
| Key Vault | `Azure/avm-res-keyvault-vault/azurerm` | ✅ Recommended |
| Virtual Network | `Azure/avm-res-network-virtualnetwork/azurerm` | ✅ Recommended |
| User Assigned Identity | `Azure/avm-res-managedidentity-userassignedidentity/azurerm` | ✅ Recommended |

### AVM Usage Pattern

```hcl
module "aks" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "~> 0.2.0"  # Pin version
  
  name                = module.naming.aks_cluster
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  
  # Enable telemetry (required by AVM)
  enable_telemetry = var.enable_telemetry
  
  # AKS configuration
  kubernetes_version = "1.28.5"
  network_plugin     = "azure"
  network_policy     = "calico"
  
  # ... other configuration
}
```

**AVM Benefits:**
- ✅ Microsoft-supported
- ✅ Security-hardened by default
- ✅ Follows Azure best practices
- ✅ Regular updates and CVE patches
- ✅ Comprehensive testing

**Registry**: [Azure/terraform-azurerm-avm](https://registry.terraform.io/namespaces/Azure)

## Naming Convention

This agent uses the **naming module** for CAF-compliant names:

```hcl
module "naming" {
  source = "./modules/naming"
  
  project_name = var.project_name  # e.g., "threehorizons"
  environment  = var.environment   # e.g., "prd"
  location     = var.location      # e.g., "brazilsouth"
}

# Usage
resource "azurerm_kubernetes_cluster" "main" {
  name = module.naming.aks_cluster  # aks-threehorizons-prd-brs
}
```

### Resource Naming Patterns

| Resource | Pattern | Example |
|----------|---------|---------|
| Resource Group | `rg-{project}-{env}-{region}` | `rg-threehorizons-prd-brs` |
| AKS Cluster | `aks-{project}-{env}-{region}` | `aks-threehorizons-prd-brs` |
| Container Registry | `cr{project}{env}{region}` | `crthreehorizonsprdbrs` |
| Key Vault | `kv-{project}-{env}-{region}` | `kv-threehorizons-prd-brs` |
| VNet | `vnet-{project}-{env}-{region}` | `vnet-threehorizons-prd-brs` |

⚠️ **Critical Naming Rules:**
- **ACR**: No hyphens allowed, alphanumeric only
- **Storage Account**: No hyphens, lowercase + numbers only, max 24 chars
- **Key Vault**: Max 24 characters

## Workflow

```yaml
# Triggered by: infrastructure.yml issue
# Dependencies: None (foundation)

steps:
  - name: Validate Prerequisites
    run: ./scripts/validate-cli-prerequisites.sh
    
  - name: Validate Naming
    run: ./scripts/validate-naming.sh --all $PROJECT $ENV $REGION
    
  - name: Initialize Terraform
    run: |
      cd terraform
      terraform init
      
  - name: Plan Infrastructure
    run: terraform plan -out=tfplan
    
  - name: Apply Infrastructure
    run: terraform apply tfplan
    
  - name: Output Summary
    run: terraform output -json > infrastructure-summary.json
```

## Dependencies

### Requires
- Azure subscription with Owner/Contributor access
- Entra ID permissions for managed identities
- GitHub repository for GitOps

### Enables
- `security-agent` - Key Vault configuration
- `gitops-agent` - ArgoCD deployment
- `rhdh-portal-agent` - Developer portal
- `observability-agent` - Monitoring stack

## Configuration

### Sizing Profiles

See `config/sizing-profiles.yaml`:

| Profile | Nodes | VM Size | Use Case |
|---------|-------|---------|----------|
| small | 3 | D4s_v3 | Development |
| medium | 5 | D8s_v3 | Staging |
| large | 10 | D16s_v3 | Production |
| xlarge | 20 | D32s_v3 | Enterprise |

### Region Availability

See `config/region-availability.yaml` for service availability by region.

## Example Usage

```bash
# 1. Validate prerequisites
./scripts/validate-cli-prerequisites.sh

# 2. Validate naming
./scripts/validate-naming.sh --all myproject prd brazilsouth

# 3. Deploy infrastructure
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

## Related Agents

| Agent | Relationship |
|-------|-------------|
| `networking-agent` | Provides network foundation |
| `security-agent` | Configures Key Vault and identities |
| `container-registry-agent` | Provisions ACR |
| `database-agent` | Deploys PostgreSQL/Redis |
| `validation-agent` | Validates deployment |
