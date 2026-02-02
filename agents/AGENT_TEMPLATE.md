# Agent Template (v2.0)

> **Based on GitHub Agentic Workflows patterns**  
> **Reference**: https://githubnext.com/projects/agentic-workflows/

## Template Structure

```markdown
---
name: "{Agent Name}"
version: "2.0.0"
horizon: "H1|H2|H3|cross-cutting"
status: "stable|beta|deprecated"
last_updated: "2026-02-02"
skills:
  - terraform-cli          # If uses Terraform
  - azure-cli              # If uses Azure
  - kubectl-cli            # If uses Kubernetes
  - argocd-cli             # If uses ArgoCD
  - helm-cli               # If uses Helm
  - github-cli             # If uses GitHub operations
  - validation-scripts     # All agents should use this
dependencies:
  - dependency-agent-1
  - dependency-agent-2
---

# {Agent Name}

## 🤖 Agent Identity

```yaml
name: {agent-name}
version: 2.0.0
horizon: H{1|2|3} - {Foundation|Enhancement|Innovation}
description: |
  {Brief description of what this agent does}
  
  Version 2.0 updates:
  - Replaced fictional MCP servers with real skills from .github/skills/
  - Added explicit consent patterns for destructive operations
  - Enhanced validation with real scripts from .github/skills/validation-scripts/
  - Integrated CLI best practices (terraform-cli, azure-cli, kubectl-cli, etc.)
  - Added Azure Verified Modules (AVM) references where applicable
  - Added Terraform best practices (tflint, tfsec, terraform-docs)
  
author: Microsoft LATAM Platform Engineering
model_compatibility:
  - GitHub Copilot Agent Mode
  - GitHub Copilot Coding Agent
  - Claude with MCP
```

---

## 💡 Skills Integration

This agent leverages the following skills from `.github/skills/`:

| Skill | Path | Usage |
|-------|------|-------|
| **terraform-cli** | `.github/skills/terraform-cli/` | Terraform operations (init, plan, apply, validate) |
| **azure-cli** | `.github/skills/azure-cli/` | Azure resource management and validation |
| **kubectl-cli** | `.github/skills/kubectl-cli/` | Kubernetes cluster operations |
| **validation-scripts** | `.github/skills/validation-scripts/` | Reusable validation patterns |

**Tool declarations** (GitHub Agentic Workflows pattern):

```yaml
tools:
  terraform:
    description: "Terraform CLI for infrastructure as code"
    commands: ["init", "plan", "apply", "validate", "fmt"]
  azure-cli:
    description: "Azure CLI for resource management"
    commands: ["az aks", "az acr", "az keyvault", "az network"]
  kubectl:
    description: "Kubernetes CLI for cluster operations"
    commands: ["get", "describe", "apply", "delete"]
```

---

## 🛑 Explicit Consent Required

**IMPORTANT**: This agent follows **GitHub Agentic Workflows** security-first principles:

- ✋ **Read-only by default**: All operations default to read-only
- ✋ **Explicit consent for writes**: User confirmation required for state-modifying commands
- ✋ **Safe-outputs only**: Write operations only via sanitized safe-outputs

**Commands requiring explicit user confirmation**:

- `terraform apply` - Infrastructure deployment (creates/modifies/deletes resources)
- `az resource delete` - Resource deletion
- `kubectl delete` - Kubernetes resource removal
- `{other destructive commands for this agent}`

**Default behavior**: When in doubt, **no action** is taken until explicit "yes" is received.

**Example prompts**:
```
Should I proceed with terraform apply to create 12 resources in subscription 'prod-subscription'? (yes/no)
Should I proceed with deleting {resource-type} '{resource-name}'? (yes/no)
```

---

## 🎯 Capabilities

| Capability | Description | Complexity |
|------------|-------------|------------|
| **Capability 1** | Description | Low/Medium/High |
| **Capability 2** | Description | Low/Medium/High |

---

## 📋 Terraform Best Practices

*(Include if agent uses Terraform)*

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
resource "azurerm_resource" "example" {
  name                = "example"
  resource_group_name = azurerm_resource_group.main.name  # Implicit
}

# ❌ Bad - Unnecessary explicit dependency
resource "azurerm_resource" "example" {
  name                = "example"
  resource_group_name = azurerm_resource_group.main.name
  depends_on          = [azurerm_resource_group.main]  # Redundant!
}
```

### Pre-commit Hooks

Recommended `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_docs
      - id: terraform_tflint
      - id: terraform_tfsec
```

---

## 🏗️ Azure Verified Modules (AVM)

*(Include for Azure infrastructure agents)*

This agent uses **Azure Verified Modules** where available:

| Azure Resource | AVM Module | Version |
|----------------|------------|---------|
| Resource 1 | `Azure/avm-res-{service}-{resource}/azurerm` | ~> 0.x.0 |
| Resource 2 | `Azure/avm-res-{service}-{resource}/azurerm` | ~> 0.x.0 |

### AVM Usage Pattern

```hcl
module "example" {
  source  = "Azure/avm-res-{service}-{resource}/azurerm"
  version = "~> 0.2.0"  # Pin version
  
  name                = module.naming.resource_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  
  # Enable telemetry (required by AVM)
  enable_telemetry = var.enable_telemetry
  
  # ... configuration
}
```

**AVM Benefits:**
- ✅ Microsoft-supported
- ✅ Security-hardened by default
- ✅ Follows Azure best practices
- ✅ Regular updates and CVE patches

**Registry**: [Azure/terraform-azurerm-avm](https://registry.terraform.io/namespaces/Azure)

---

## ✅ Validation

### Pre-flight Checks

Before deployment, this agent performs comprehensive validation using `.github/skills/validation-scripts/`:

```bash
# 1. Validate Azure resources
./.github/skills/validation-scripts/validate-azure-resources.sh \
  --subscription-id $SUBSCRIPTION_ID \
  --resource-group $RESOURCE_GROUP

# 2. Validate Terraform state
./.github/skills/validation-scripts/validate-terraform-state.sh \
  --working-dir ./terraform

# 3. Detect drift
./.github/skills/validation-scripts/detect-drift.sh
```

### Post-deployment Validation

| Check | Command | Expected Result |
|-------|---------|-----------------|
| Check 1 | `command` | Expected |
| Check 2 | `command` | Expected |

### Health Checks

```bash
# Comprehensive health check
gh issue comment $ISSUE_NUMBER --body "
## {Agent Name} Health Check

### Resource Status
- ✅ Resource 1: {status}
- ✅ Resource 2: {status}

### Validation Results
- ✅ Check 1: Passed
- ✅ Check 2: Passed
"
```

---

## 🔄 Workflow

### GitHub Agentic Workflow Pattern

```markdown
---
on:
  issues:
    types: [opened, labeled]
    
permissions:
  contents: read
  issues: write
  pull-requests: write
  
safe-outputs:
  create-issue:
    title-prefix: "[{agent-name}] "
    labels: ["agent:{agent-name}", "automated"]
  create-pull-request:
    branch-prefix: "{agent-name}/"
    
tools:
  terraform:
  azure-cli:
  kubectl:
---

# {Agent Name} Workflow

You are the {Agent Name} for the Three Horizons Platform.

## Context

- Repository: ${{ github.repository }}
- Issue: #${{ github.event.issue.number }}
- Triggered by: ${{ github.actor }}

## Steps

1. **Validate Prerequisites**
   - Check Azure CLI authentication
   - Verify Terraform version
   - Validate naming conventions
   
2. **Plan Changes**
   - Run `terraform init`
   - Run `terraform plan -out=tfplan`
   - Review plan output
   
3. **Request User Confirmation**
   - Show plan summary
   - Ask: "Should I proceed with terraform apply? (yes/no)"
   - Wait for explicit confirmation
   
4. **Apply Changes** (if confirmed)
   - Run `terraform apply tfplan`
   - Monitor progress
   - Handle errors gracefully
   
5. **Validate Deployment**
   - Run post-deployment validation scripts
   - Check resource health
   - Update issue with results
   
6. **Report Status**
   - Create summary comment on issue
   - Close issue on success
   - Tag on-call team on failure
```

### Traditional GitHub Actions Workflow

*(Alternative for non-agentic deployment)*

```yaml
# .github/workflows/{agent-name}.yml
name: {Agent Name}

on:
  issues:
    types: [opened, labeled]
  workflow_dispatch:

permissions:
  contents: read
  issues: write
  id-token: write  # For Azure OIDC

jobs:
  validate:
    runs-on: ubuntu-latest
    if: contains(github.event.issue.labels.*.name, 'agent:{agent-name}')
    steps:
      - uses: actions/checkout@v4
      
      - name: Validate Prerequisites
        run: ./scripts/validate-cli-prerequisites.sh
      
      - name: Validate Configuration
        run: ./scripts/validate-config.sh
  
  plan:
    needs: validate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login (OIDC)
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform
      
      - name: Terraform Validate
        run: |
          terraform fmt -check -recursive
          terraform validate
          tfsec . --minimum-severity MEDIUM
        working-directory: ./terraform
      
      - name: Terraform Plan
        run: terraform plan -out=tfplan
        working-directory: ./terraform
      
      - name: Upload Plan
        uses: actions/upload-artifact@v3
        with:
          name: tfplan
          path: terraform/tfplan
  
  approval:
    needs: plan
    runs-on: ubuntu-latest
    environment: production  # Requires manual approval
    steps:
      - name: Approval Checkpoint
        run: echo "Approved by ${{ github.actor }}"
  
  apply:
    needs: approval
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Download Plan
        uses: actions/download-artifact@v3
        with:
          name: tfplan
          path: terraform
      
      - name: Terraform Apply
        run: terraform apply tfplan
        working-directory: ./terraform
      
      - name: Post-deployment Validation
        run: |
          ./.github/skills/validation-scripts/validate-azure-resources.sh
        
      - name: Update Issue
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body: '✅ Deployment completed successfully!'
            })
```

---

## 📊 Dependencies

### Requires
- Dependency 1 (reason)
- Dependency 2 (reason)

### Enables
- Dependent Agent 1 (reason)
- Dependent Agent 2 (reason)

---

## 📚 Documentation References

### Official Documentation
- [Azure Service Documentation](https://learn.microsoft.com/azure/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

### Best Practices
- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [GitHub Agentic Workflows](https://githubnext.github.io/gh-aw/)

---

## 🤝 Related Agents

| Agent | Relationship | Communication |
|-------|--------------|---------------|
| agent-1 | Prerequisite | Provides X |
| agent-2 | Parallel | Shares Y |
| agent-3 | Dependent | Consumes Z |

---

**Agent Version:** 2.0.0  
**Last Updated:** 2026-02-02  
**Compliance Status:** ✅ GitHub Agentic Workflows compatible
