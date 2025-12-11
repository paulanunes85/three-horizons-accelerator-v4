# Three Horizons Accelerator - Complete Deployment Guide

> **Version:** 4.0.0
> **Last Updated:** December 2025
> **Estimated Time:** 2-4 hours (full platform)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Prerequisites](#2-prerequisites)
3. [Step 1: Azure Environment Setup](#step-1-azure-environment-setup)
4. [Step 2: GitHub Organization Setup](#step-2-github-organization-setup)
5. [Step 3: Clone and Initial Configuration](#step-3-clone-and-initial-configuration)
6. [Step 4: Deploy H1 Foundation](#step-4-deploy-h1-foundation)
7. [Step 5: Verify H1 Foundation](#step-5-verify-h1-foundation)
8. [Step 6: Deploy H2 Enhancement](#step-6-deploy-h2-enhancement)
9. [Step 7: Verify H2 Enhancement](#step-7-verify-h2-enhancement)
10. [Step 8: Deploy H3 Innovation](#step-8-deploy-h3-innovation)
11. [Step 9: Final Platform Verification](#step-9-final-platform-verification)
12. [Step 10: Post-Deployment Configuration](#step-10-post-deployment-configuration)
13. [Appendix A: File Reference](#appendix-a-file-reference)
14. [Appendix B: Environment Variables](#appendix-b-environment-variables)
15. [Appendix C: Rollback Procedures](#appendix-c-rollback-procedures)

---

## 1. Overview

### What You Will Deploy

```
┌─────────────────────────────────────────────────────────────────────┐
│                    THREE HORIZONS PLATFORM                          │
├─────────────────────────────────────────────────────────────────────┤
│  H3: INNOVATION (Optional)                                          │
│  ├── AI Foundry (Azure OpenAI)                                      │
│  ├── MLOps Pipelines                                                │
│  └── Intelligent Agents                                             │
├─────────────────────────────────────────────────────────────────────┤
│  H2: ENHANCEMENT                                                    │
│  ├── ArgoCD (GitOps)                                                │
│  ├── RHDH Portal (Developer Experience)                             │
│  ├── External Secrets Operator                                      │
│  ├── Observability (Prometheus + Grafana)                           │
│  └── Gatekeeper (Policy Enforcement)                                │
├─────────────────────────────────────────────────────────────────────┤
│  H1: FOUNDATION                                                     │
│  ├── AKS Cluster                                                    │
│  ├── Azure Container Registry                                       │
│  ├── Azure Key Vault                                                │
│  ├── Virtual Network + Subnets                                      │
│  ├── Defender for Cloud                                             │
│  ├── Microsoft Purview                                              │
│  └── Managed Identities                                             │
└─────────────────────────────────────────────────────────────────────┘
```

### Deployment Order

| Phase | Components | Time | Dependencies |
|-------|-----------|------|--------------|
| **Phase 1** | Azure Prerequisites | 30 min | Azure Subscription |
| **Phase 2** | GitHub Setup | 15 min | GitHub Organization |
| **Phase 3** | H1 Foundation | 30 min | Phase 1, 2 |
| **Phase 4** | H2 Enhancement | 30 min | Phase 3 |
| **Phase 5** | H3 Innovation | 30 min | Phase 4 (optional) |
| **Phase 6** | Verification | 30 min | All phases |

---

## 2. Prerequisites

### 2.1 Required Tools

Install all required tools before proceeding:

```bash
# Run prerequisites check script
./scripts/validate-cli-prerequisites.sh
```

| Tool | Minimum Version | Installation |
|------|-----------------|--------------|
| Azure CLI | 2.50.0 | `curl -sL https://aka.ms/InstallAzureCLIDeb \| sudo bash` |
| Terraform | 1.5.0 | `brew install terraform` or [terraform.io](https://terraform.io/downloads) |
| kubectl | 1.28.0 | `az aks install-cli` |
| Helm | 3.12.0 | `brew install helm` |
| GitHub CLI | 2.30.0 | `brew install gh` |
| jq | 1.6 | `brew install jq` |
| yq | 4.30.0 | `brew install yq` |
| Git | 2.40.0 | `brew install git` |

### 2.2 Required Permissions

#### Azure Permissions
- **Subscription**: Owner or Contributor + User Access Administrator
- **Entra ID**: Application Administrator (for Workload Identity)
- **Resource Providers**: Must be registered (script handles this)

#### GitHub Permissions
- **Organization**: Owner or Admin
- **Repository**: Admin access to create secrets and configure Actions

### 2.3 Required Information

Gather this information before starting:

```yaml
# Save this as deployment-info.yaml for reference
azure:
  subscription_id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  tenant_id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  location: "brazilsouth"  # or eastus2, southcentralus

github:
  organization: "your-org-name"
  admin_email: "admin@company.com"

project:
  name: "threehorizons"  # lowercase, no spaces, max 12 chars
  environment: "dev"      # dev, staging, prod

contact:
  owner_email: "owner@company.com"
  team_name: "Platform Engineering"
```

---

## Step 1: Azure Environment Setup

**Time:** 30 minutes
**Files:** `scripts/validate-cli-prerequisites.sh`

### 1.1 Authenticate to Azure

```bash
# Login to Azure
az login

# List available subscriptions
az account list --output table

# Set the target subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Verify the correct subscription is selected
az account show --query '{Name:name, ID:id, State:state}' --output table
```

**Expected Output:**
```
Name                    ID                                    State
----------------------  ------------------------------------  -------
Your Subscription Name  xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  Enabled
```

### 1.2 Register Required Resource Providers

```bash
# Register all required providers (takes 2-5 minutes)
az provider register --namespace Microsoft.ContainerService --wait
az provider register --namespace Microsoft.ContainerRegistry --wait
az provider register --namespace Microsoft.KeyVault --wait
az provider register --namespace Microsoft.Network --wait
az provider register --namespace Microsoft.ManagedIdentity --wait
az provider register --namespace Microsoft.Security --wait
az provider register --namespace Microsoft.Purview --wait
az provider register --namespace Microsoft.CognitiveServices --wait
az provider register --namespace Microsoft.AlertsManagement --wait
az provider register --namespace Microsoft.Monitor --wait

# Verify all providers are registered
az provider list --query "[?registrationState=='Registered'].namespace" \
  --output table | grep -E "Container|KeyVault|Network|Identity|Security|Purview|Cognitive"
```

**Expected Output:**
```
Microsoft.ContainerRegistry
Microsoft.ContainerService
Microsoft.KeyVault
Microsoft.Network
Microsoft.ManagedIdentity
Microsoft.Security
Microsoft.Purview
Microsoft.CognitiveServices
```

### 1.3 Create Service Principal for Terraform

```bash
# Set variables
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SP_NAME="sp-threehorizons-terraform"

# Create service principal with Contributor role
az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID" \
  --sdk-auth > azure-credentials.json

# IMPORTANT: Save this output securely!
cat azure-credentials.json
```

**Expected Output (save this!):**
```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  ...
}
```

### 1.4 Grant Additional Permissions

```bash
# Get the service principal object ID
SP_OBJECT_ID=$(az ad sp list --display-name "$SP_NAME" --query "[0].id" -o tsv)

# Grant User Access Administrator (for RBAC assignments)
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "User Access Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# Grant Key Vault Administrator (for secrets management)
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "Key Vault Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

### 1.5 Verify Azure Setup

```bash
# Run verification
echo "=== Azure Setup Verification ==="
echo "Subscription: $(az account show --query name -o tsv)"
echo "Location: brazilsouth"
echo "Service Principal: $SP_NAME"
echo ""
echo "Resource Providers:"
az provider list --query "[?namespace=='Microsoft.ContainerService'].{Namespace:namespace, State:registrationState}" -o table
```

**Checkpoint:** Save `azure-credentials.json` securely. You will need these values in Step 3.

---

## Step 2: GitHub Organization Setup

**Time:** 15 minutes
**Files:** `.github/workflows/*.yml`

### 2.1 Authenticate to GitHub

```bash
# Login to GitHub CLI
gh auth login

# Verify authentication
gh auth status

# Verify organization access
gh api /orgs/YOUR_ORG_NAME --jq '.login'
```

### 2.2 Fork or Clone the Repository

**Option A: Fork (Recommended for customization)**
```bash
# Fork to your organization
gh repo fork three-horizons/accelerator-v4 \
  --org YOUR_ORG_NAME \
  --clone \
  --remote

cd three-horizons-accelerator-v4
```

**Option B: Clone directly**
```bash
git clone https://github.com/three-horizons/accelerator-v4.git three-horizons-accelerator-v4
cd three-horizons-accelerator-v4
```

### 2.3 Configure Repository Secrets

```bash
# Set Azure credentials as repository secrets
gh secret set AZURE_CREDENTIALS < azure-credentials.json

# Set individual secrets for Terraform
gh secret set ARM_CLIENT_ID --body "$(jq -r .clientId azure-credentials.json)"
gh secret set ARM_CLIENT_SECRET --body "$(jq -r .clientSecret azure-credentials.json)"
gh secret set ARM_SUBSCRIPTION_ID --body "$(jq -r .subscriptionId azure-credentials.json)"
gh secret set ARM_TENANT_ID --body "$(jq -r .tenantId azure-credentials.json)"

# Verify secrets were created
gh secret list
```

**Expected Output:**
```
NAME                 UPDATED
AZURE_CREDENTIALS    now
ARM_CLIENT_ID        now
ARM_CLIENT_SECRET    now
ARM_SUBSCRIPTION_ID  now
ARM_TENANT_ID        now
```

### 2.4 Configure Repository Variables

```bash
# Set environment variables
gh variable set PROJECT_NAME --body "threehorizons"
gh variable set ENVIRONMENT --body "dev"
gh variable set AZURE_LOCATION --body "brazilsouth"
gh variable set GITHUB_ORG --body "YOUR_ORG_NAME"

# Verify variables
gh variable list
```

### 2.5 Enable GitHub Actions

```bash
# Verify Actions are enabled
gh api /repos/YOUR_ORG_NAME/three-horizons-accelerator-v4/actions/permissions \
  --jq '.enabled'
```

**Expected Output:** `true`

---

## Step 3: Clone and Initial Configuration

**Time:** 15 minutes
**Files:** `terraform/terraform.tfvars`, `config/sizing-profiles.yaml`

### 3.1 Navigate to Repository

```bash
cd three-horizons-accelerator-v4

# Verify you're in the correct directory
ls -la
```

**Expected files:**
```
.github/          # GitHub Actions workflows
agents/           # AI agent specifications
argocd/           # GitOps configurations
config/           # Sizing profiles and configs
docs/             # Documentation
golden-paths/     # Developer templates
grafana/          # Grafana dashboards
mcp-servers/      # MCP configurations
policies/         # OPA/Gatekeeper policies
prometheus/       # Prometheus rules
scripts/          # Automation scripts
terraform/        # Infrastructure as Code
tests/            # Test files
```

### 3.2 Make Scripts Executable

```bash
chmod +x scripts/*.sh

# Verify
ls -la scripts/*.sh | head -5
```

### 3.3 Run Prerequisites Validation

```bash
./scripts/validate-cli-prerequisites.sh
```

**Expected Output:**
```
=== Three Horizons Accelerator - Prerequisites Check ===

[✓] Azure CLI: 2.50.0 (minimum: 2.50.0)
[✓] Terraform: 1.5.7 (minimum: 1.5.0)
[✓] kubectl: 1.28.0 (minimum: 1.28.0)
[✓] Helm: 3.12.0 (minimum: 3.12.0)
[✓] GitHub CLI: 2.30.0 (minimum: 2.30.0)
[✓] jq: 1.6 (minimum: 1.6)

All prerequisites met!
```

### 3.4 Create Terraform Variables File

```bash
# Copy the example file
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit with your values
nano terraform/terraform.tfvars
# Or use your preferred editor: code, vim, etc.
```

**File: `terraform/terraform.tfvars`**
```hcl
# =============================================================================
# THREE HORIZONS ACCELERATOR - TERRAFORM CONFIGURATION
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED VARIABLES - You must change these
# -----------------------------------------------------------------------------

# Project identification
project_name    = "threehorizons"    # Lowercase, no spaces, max 12 chars
environment     = "dev"               # dev, staging, prod
location        = "brazilsouth"       # Azure region

# Azure authentication
subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # From Step 1.1
tenant_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # From azure-credentials.json

# GitHub integration
github_org      = "your-org-name"     # Your GitHub organization
github_repo     = "three-horizons-accelerator-v4"

# -----------------------------------------------------------------------------
# HORIZON ENABLEMENT
# -----------------------------------------------------------------------------

enable_h1 = true   # Foundation (always true)
enable_h2 = true   # Enhancement (ArgoCD, RHDH, Observability)
enable_h3 = false  # Innovation (AI Foundry) - enable after H1+H2 stable

# -----------------------------------------------------------------------------
# SIZING CONFIGURATION
# -----------------------------------------------------------------------------

# Choose: small, medium, large, xlarge
sizing_profile = "small"

# Or customize individually:
# aks_node_count     = 3
# aks_node_size      = "Standard_D4s_v5"
# database_sku       = "Basic"
# ai_model_capacity  = 10

# -----------------------------------------------------------------------------
# NETWORKING
# -----------------------------------------------------------------------------

vnet_cidr = "10.0.0.0/16"

subnet_config = {
  aks_nodes         = "10.0.0.0/22"    # 1024 IPs
  aks_pods          = "10.0.16.0/20"   # 4096 IPs
  private_endpoints = "10.0.4.0/24"    # 256 IPs
  bastion           = "10.0.5.0/26"    # 64 IPs
  app_gateway       = "10.0.6.0/24"    # 256 IPs
}

# -----------------------------------------------------------------------------
# SECURITY
# -----------------------------------------------------------------------------

enable_defender       = true
enable_purview        = true
enable_private_cluster = false  # Set true for production

# -----------------------------------------------------------------------------
# TAGS
# -----------------------------------------------------------------------------

tags = {
  Project       = "ThreeHorizons"
  Environment   = "Development"
  Owner         = "platform-team@company.com"
  CostCenter    = "PLATFORM-001"
  Compliance    = "LGPD"
  ManagedBy     = "Terraform"
}
```

### 3.5 Validate Configuration

```bash
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format check
terraform fmt -check -recursive
```

**Expected Output:**
```
Initializing the backend...
Initializing provider plugins...

Terraform has been successfully initialized!

Success! The configuration is valid.
```

### 3.6 Run Naming Convention Validation

```bash
cd ..
./scripts/validate-naming.sh --project threehorizons --environment dev
```

---

## Step 4: Deploy H1 Foundation

**Time:** 30 minutes
**Files:** `terraform/modules/`, `terraform/main.tf`

### 4.1 Review the Deployment Plan

```bash
cd terraform

# Generate execution plan
terraform plan -out=h1-foundation.tfplan

# Review the plan output
# Expected: ~25-35 resources to be created
```

**Expected Resources:**
```
Plan: 32 to add, 0 to change, 0 to destroy.

Resources to be created:
+ azurerm_resource_group.main
+ azurerm_virtual_network.main
+ azurerm_subnet.aks_nodes
+ azurerm_subnet.aks_pods
+ azurerm_subnet.private_endpoints
+ azurerm_network_security_group.aks
+ azurerm_network_security_group.private_endpoints
+ azurerm_kubernetes_cluster.main
+ azurerm_container_registry.main
+ azurerm_key_vault.main
+ azurerm_user_assigned_identity.aks
+ azurerm_user_assigned_identity.workload
+ azurerm_private_dns_zone.keyvault
+ azurerm_private_dns_zone.acr
... (and more)
```

### 4.2 Apply H1 Foundation

```bash
# Apply the plan
terraform apply h1-foundation.tfplan
```

**Progress Indicators:**
```
azurerm_resource_group.main: Creating...
azurerm_resource_group.main: Creation complete after 2s

azurerm_virtual_network.main: Creating...
azurerm_virtual_network.main: Creation complete after 8s

azurerm_kubernetes_cluster.main: Creating...
azurerm_kubernetes_cluster.main: Still creating... [2m elapsed]
azurerm_kubernetes_cluster.main: Still creating... [4m elapsed]
azurerm_kubernetes_cluster.main: Creation complete after 6m32s

Apply complete! Resources: 32 added, 0 changed, 0 destroyed.
```

### 4.3 Save Outputs

```bash
# Save all outputs for reference
terraform output -json > ../outputs/h1-outputs.json

# Display key outputs
terraform output
```

**Expected Output:**
```
Outputs:

aks_cluster_name     = "aks-threehorizons-dev"
aks_cluster_id       = "/subscriptions/.../managedClusters/aks-threehorizons-dev"
acr_login_server     = "acrthreehorizonsdev.azurecr.io"
acr_id               = "/subscriptions/.../containerRegistries/acrthreehorizonsdev"
key_vault_name       = "kv-threehorizons-dev"
key_vault_uri        = "https://kv-threehorizons-dev.vault.azure.net/"
resource_group_name  = "rg-threehorizons-dev"
vnet_id              = "/subscriptions/.../virtualNetworks/vnet-threehorizons-dev"
workload_identity_id = "/subscriptions/.../userAssignedIdentities/id-threehorizons-dev-workload"
```

---

## Step 5: Verify H1 Foundation

**Time:** 15 minutes

### 5.1 Connect to AKS Cluster

```bash
# Get AKS credentials
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name) \
  --overwrite-existing

# Verify connection
kubectl cluster-info
```

**Expected Output:**
```
Kubernetes control plane is running at https://aks-threehorizons-dev-xxxxx.hcp.brazilsouth.azmk8s.io:443
CoreDNS is running at https://aks-threehorizons-dev-xxxxx.hcp.brazilsouth.azmk8s.io:443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

### 5.2 Verify Nodes

```bash
kubectl get nodes -o wide
```

**Expected Output:**
```
NAME                              STATUS   ROLES   AGE   VERSION   OS-IMAGE
aks-system-12345678-vmss000000    Ready    agent   10m   v1.29.0   Ubuntu 22.04.3 LTS
aks-system-12345678-vmss000001    Ready    agent   10m   v1.29.0   Ubuntu 22.04.3 LTS
aks-system-12345678-vmss000002    Ready    agent   10m   v1.29.0   Ubuntu 22.04.3 LTS
```

### 5.3 Verify Core Components

```bash
# Check system pods
kubectl get pods -n kube-system

# Check all namespaces
kubectl get namespaces
```

**Expected Namespaces:**
```
NAME              STATUS   AGE
default           Active   15m
kube-node-lease   Active   15m
kube-public       Active   15m
kube-system       Active   15m
```

### 5.4 Verify Azure Resources

```bash
# List all resources in resource group
az resource list \
  --resource-group $(terraform output -raw resource_group_name) \
  --output table
```

**Expected Resources:**
```
Name                              ResourceGroup           Location      Type
--------------------------------  ----------------------  ------------  ----------------------------------------
aks-threehorizons-dev             rg-threehorizons-dev    brazilsouth   Microsoft.ContainerService/managedClusters
acrthreehorizonsdev               rg-threehorizons-dev    brazilsouth   Microsoft.ContainerRegistry/registries
kv-threehorizons-dev              rg-threehorizons-dev    brazilsouth   Microsoft.KeyVault/vaults
vnet-threehorizons-dev            rg-threehorizons-dev    brazilsouth   Microsoft.Network/virtualNetworks
nsg-aks-threehorizons-dev         rg-threehorizons-dev    brazilsouth   Microsoft.Network/networkSecurityGroups
id-threehorizons-dev-aks          rg-threehorizons-dev    brazilsouth   Microsoft.ManagedIdentity/userAssignedIdentities
id-threehorizons-dev-workload     rg-threehorizons-dev    brazilsouth   Microsoft.ManagedIdentity/userAssignedIdentities
```

### 5.5 Test ACR Access

```bash
# Login to ACR
az acr login --name $(terraform output -raw acr_login_server | cut -d'.' -f1)

# Verify access
az acr repository list --name $(terraform output -raw acr_login_server | cut -d'.' -f1)
```

### 5.6 H1 Verification Checklist

```bash
./scripts/validate-deployment.sh --horizon h1
```

**Manual Checklist:**
- [ ] AKS cluster is running with 3 nodes
- [ ] All nodes are in Ready state
- [ ] kube-system pods are all Running
- [ ] ACR is accessible
- [ ] Key Vault is created
- [ ] VNet and subnets are configured
- [ ] NSGs are applied

---

## Step 6: Deploy H2 Enhancement

**Time:** 30 minutes
**Files:** `argocd/`, `terraform/modules/observability/`, `terraform/modules/argocd/`

### 6.1 Create Required Namespaces

```bash
# Create namespaces for H2 components
kubectl create namespace argocd
kubectl create namespace rhdh
kubectl create namespace observability
kubectl create namespace external-secrets
kubectl create namespace gatekeeper-system

# Verify namespaces
kubectl get namespaces | grep -E "argocd|rhdh|observability|external|gatekeeper"
```

### 6.2 Deploy ArgoCD

```bash
# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

# Get initial admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

echo "ArgoCD Admin Password: $ARGOCD_PASSWORD"
```

### 6.3 Configure ArgoCD

```bash
# Apply ArgoCD configuration
kubectl apply -f argocd/argocd-cm.yaml
kubectl apply -f argocd/argocd-rbac-cm.yaml

# Apply App-of-Apps pattern
kubectl apply -f argocd/apps/app-of-apps.yaml

# Verify applications are being created
kubectl get applications -n argocd
```

**Expected Output:**
```
NAME                SYNC STATUS   HEALTH STATUS
app-of-apps         Synced        Healthy
external-secrets    Synced        Healthy
gatekeeper          Synced        Healthy
observability       Synced        Healthy
```

### 6.4 Deploy External Secrets Operator

```bash
# Add Helm repository
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# Install External Secrets Operator
helm install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets \
  --set installCRDs=true \
  --wait

# Verify installation
kubectl get pods -n external-secrets
```

### 6.5 Configure ClusterSecretStore

```bash
# Get Key Vault name
KV_NAME=$(terraform output -raw key_vault_name)
TENANT_ID=$(az account show --query tenantId -o tsv)

# Apply ClusterSecretStore
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: azure-key-vault
spec:
  provider:
    azurekv:
      authType: WorkloadIdentity
      vaultUrl: "https://${KV_NAME}.vault.azure.net"
      serviceAccountRef:
        name: external-secrets
        namespace: external-secrets
EOF

# Verify
kubectl get clustersecretstore
```

### 6.6 Deploy Observability Stack

```bash
# Add Prometheus community Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n observability \
  --values prometheus/values.yaml \
  --wait

# Import Grafana dashboards
kubectl apply -f grafana/dashboards/

# Verify installation
kubectl get pods -n observability
```

### 6.7 Deploy Gatekeeper

```bash
# Install Gatekeeper
helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
helm repo update

helm install gatekeeper gatekeeper/gatekeeper \
  -n gatekeeper-system \
  --set replicas=2 \
  --wait

# Apply constraint templates
kubectl apply -f policies/kubernetes/

# Verify
kubectl get constrainttemplates
kubectl get constraints
```

---

## Step 7: Verify H2 Enhancement

**Time:** 15 minutes

### 7.1 Access ArgoCD UI

```bash
# Port forward ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Open in browser: https://localhost:8080
# Username: admin
# Password: (from Step 6.2)

echo "ArgoCD URL: https://localhost:8080"
echo "Username: admin"
echo "Password: $ARGOCD_PASSWORD"
```

### 7.2 Verify ArgoCD Applications

```bash
# Check all applications
kubectl get applications -n argocd

# Check application health
kubectl get applications -n argocd -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.health.status}{"\n"}{end}'
```

**Expected Output:**
```
app-of-apps         Healthy
external-secrets    Healthy
gatekeeper          Healthy
observability       Healthy
rhdh                Healthy
```

### 7.3 Access Grafana

```bash
# Get Grafana admin password
kubectl get secret -n observability prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d

# Port forward Grafana
kubectl port-forward svc/prometheus-grafana -n observability 3000:80 &

echo "Grafana URL: http://localhost:3000"
echo "Username: admin"
```

### 7.4 Verify Prometheus Targets

```bash
# Port forward Prometheus
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n observability 9090:9090 &

# Open: http://localhost:9090/targets
# All targets should be UP
```

### 7.5 Test External Secrets

```bash
# Create a test secret in Key Vault
az keyvault secret set \
  --vault-name $(terraform output -raw key_vault_name) \
  --name test-secret \
  --value "hello-from-keyvault"

# Create ExternalSecret to sync it
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: test-external-secret
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: azure-key-vault
  target:
    name: test-k8s-secret
  data:
    - secretKey: test-value
      remoteRef:
        key: test-secret
EOF

# Verify secret was created
kubectl get secret test-k8s-secret -o jsonpath='{.data.test-value}' | base64 -d
```

**Expected Output:** `hello-from-keyvault`

### 7.6 Verify Gatekeeper Policies

```bash
# List constraint templates
kubectl get constrainttemplates

# List active constraints
kubectl get constraints

# Test a policy (this should be blocked)
cat <<EOF | kubectl apply -f - 2>&1 | grep -i denied || echo "Policy working correctly if denied"
apiVersion: v1
kind: Pod
metadata:
  name: test-privileged
spec:
  containers:
  - name: test
    image: nginx
    securityContext:
      privileged: true
EOF
```

### 7.7 H2 Verification Checklist

```bash
./scripts/validate-deployment.sh --horizon h2
```

**Manual Checklist:**
- [ ] ArgoCD UI accessible
- [ ] All ArgoCD applications synced and healthy
- [ ] Prometheus scraping targets
- [ ] Grafana dashboards loading
- [ ] External Secrets syncing from Key Vault
- [ ] Gatekeeper constraints enforced

---

## Step 8: Deploy H3 Innovation

**Time:** 30 minutes (optional)
**Files:** `terraform/modules/ai-foundry/`

### 8.1 Enable H3 in Configuration

```bash
# Edit terraform.tfvars
cd terraform
sed -i 's/enable_h3 = false/enable_h3 = true/' terraform.tfvars

# Or manually edit
nano terraform.tfvars
```

### 8.2 Plan H3 Deployment

```bash
# Generate plan
terraform plan -out=h3-innovation.tfplan
```

**Expected New Resources:**
```
Plan: 8 to add, 0 to change, 0 to destroy.

Resources to be created:
+ azurerm_cognitive_account.ai_foundry
+ azurerm_cognitive_deployment.gpt4o
+ azurerm_cognitive_deployment.gpt4o_mini
+ azurerm_cognitive_deployment.text_embedding
+ azurerm_private_endpoint.ai_foundry
+ azurerm_private_dns_zone.openai
...
```

### 8.3 Apply H3 Deployment

```bash
terraform apply h3-innovation.tfplan
```

### 8.4 Verify AI Foundry

```bash
# List cognitive services accounts
az cognitiveservices account list \
  --resource-group $(terraform output -raw resource_group_name) \
  --output table

# List deployments
az cognitiveservices account deployment list \
  --name $(terraform output -raw ai_foundry_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --output table
```

**Expected Output:**
```
Name              Model        Version   Capacity   State
----------------  -----------  --------  ---------  ---------
gpt-4o            gpt-4o       2024-05   10         Succeeded
gpt-4o-mini       gpt-4o-mini  2024-07   20         Succeeded
text-embedding    text-embed   3-large   50         Succeeded
```

### 8.5 Test AI Endpoint

```bash
# Get endpoint and key
AI_ENDPOINT=$(az cognitiveservices account show \
  --name $(terraform output -raw ai_foundry_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --query "properties.endpoint" -o tsv)

AI_KEY=$(az cognitiveservices account keys list \
  --name $(terraform output -raw ai_foundry_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --query "key1" -o tsv)

# Test API call
curl -X POST "${AI_ENDPOINT}openai/deployments/gpt-4o-mini/chat/completions?api-version=2024-02-15-preview" \
  -H "Content-Type: application/json" \
  -H "api-key: ${AI_KEY}" \
  -d '{
    "messages": [{"role": "user", "content": "Say hello in Portuguese"}],
    "max_tokens": 50
  }'
```

### 8.6 Store AI Key in Key Vault

```bash
# Store the API key in Key Vault for applications
az keyvault secret set \
  --vault-name $(terraform output -raw key_vault_name) \
  --name ai-foundry-api-key \
  --value "$AI_KEY"

echo "AI API key stored in Key Vault as 'ai-foundry-api-key'"
```

---

## Step 9: Final Platform Verification

**Time:** 30 minutes

### 9.1 Run Complete Validation

```bash
./scripts/validate-deployment.sh --all
```

### 9.2 Platform Health Dashboard

```bash
echo "=== THREE HORIZONS PLATFORM STATUS ==="
echo ""
echo "--- H1 Foundation ---"
kubectl get nodes -o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[-1].type,VERSION:.status.nodeInfo.kubeletVersion
echo ""
echo "--- H2 Enhancement ---"
kubectl get applications -n argocd -o custom-columns=APP:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status
echo ""
echo "--- Namespaces ---"
kubectl get namespaces --no-headers | wc -l
echo " total namespaces"
echo ""
echo "--- Pods by Namespace ---"
kubectl get pods -A --no-headers | awk '{print $1}' | sort | uniq -c | sort -rn | head -10
```

### 9.3 Connectivity Matrix

| Source | Target | How to Verify |
|--------|--------|---------------|
| Local → AKS | kubectl access | `kubectl get nodes` |
| Local → ArgoCD | Port forward | `https://localhost:8080` |
| Local → Grafana | Port forward | `http://localhost:3000` |
| Local → ACR | az acr login | `az acr login --name <acr>` |
| K8s → Key Vault | External Secrets | `kubectl get externalsecrets` |
| K8s → ACR | Image pull | `kubectl describe pod <any-pod>` |
| Prometheus → K8s | Scraping | `http://localhost:9090/targets` |

### 9.4 Generate Platform Report

```bash
./scripts/generate-platform-report.sh > platform-report-$(date +%Y%m%d).txt
```

---

## Step 10: Post-Deployment Configuration

**Time:** 30 minutes

### 10.1 Configure DNS (Optional)

```bash
# If using custom domain
az network dns record-set a add-record \
  --resource-group $(terraform output -raw resource_group_name) \
  --zone-name your-domain.com \
  --record-set-name argocd \
  --ipv4-address $(kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

### 10.2 Configure Notifications

```bash
# Edit ArgoCD notifications
kubectl edit configmap argocd-notifications-cm -n argocd

# Add Teams/Slack webhook
# See: argocd/notifications.yaml for examples
```

### 10.3 Register Golden Path Templates

```bash
# Register templates in RHDH
./scripts/register-golden-paths.sh

# Verify registration
curl -s http://localhost:7007/api/catalog/entities | jq '.[] | select(.kind=="Template") | .metadata.name'
```

### 10.4 Create First Application

Using ArgoCD UI or CLI:

```bash
# Create application using ArgoCD CLI
argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure

argocd app create sample-app \
  --repo https://github.com/$GITHUB_ORG/sample-microservice.git \
  --path k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated

argocd app sync sample-app
```

### 10.5 Enable Backup/DR (Production)

```bash
# Enable Velero for backups
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm install velero vmware-tanzu/velero \
  -n velero \
  --create-namespace \
  --values velero-values.yaml

# Create backup schedule
velero schedule create daily-backup --schedule="0 2 * * *"
```

### 10.6 Document Access Information

Create a secure document with:

```markdown
# Platform Access Information

## URLs
- ArgoCD: https://argocd.your-domain.com
- Grafana: https://grafana.your-domain.com
- RHDH: https://rhdh.your-domain.com

## Credentials Location
- ArgoCD: `kubectl get secret argocd-initial-admin-secret -n argocd`
- Grafana: `kubectl get secret prometheus-grafana -n observability`
- AI API Key: Azure Key Vault → ai-foundry-api-key

## Azure Resources
- Subscription: YOUR_SUBSCRIPTION_ID
- Resource Group: rg-threehorizons-dev
- AKS Cluster: aks-threehorizons-dev

## Contacts
- Platform Owner: platform-team@company.com
- Escalation: oncall@company.com
```

---

## Appendix A: File Reference

### Directory Structure

```
three-horizons-accelerator-v4/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                    # Continuous Integration
│   │   ├── cd.yml                    # Continuous Deployment
│   │   ├── release.yml               # Release automation
│   │   └── terraform-test.yml        # Terraform tests
│   ├── ISSUE_TEMPLATE/               # 21 issue templates
│   └── instructions/                 # Copilot instructions
│
├── agents/                           # 23 AI agent specifications
│   ├── h1-foundation/
│   ├── h2-enhancement/
│   ├── h3-innovation/
│   └── cross-cutting/
│
├── argocd/
│   ├── apps/                         # Application manifests
│   │   ├── app-of-apps.yaml          # Root application
│   │   ├── external-secrets.yaml     # Wave 0
│   │   ├── gatekeeper.yaml           # Wave 1
│   │   ├── observability.yaml        # Wave 2
│   │   └── rhdh.yaml                 # Wave 3
│   ├── applicationsets/              # ApplicationSet definitions
│   ├── argocd-cm.yaml                # ArgoCD configuration
│   └── argocd-rbac-cm.yaml           # RBAC configuration
│
├── config/
│   ├── sizing-profiles.yaml          # T-shirt sizing
│   └── regions.yaml                  # Regional configurations
│
├── docs/
│   └── guides/
│       ├── DEPLOYMENT_GUIDE.md       # This file
│       ├── ARCHITECTURE_GUIDE.md     # Architecture reference
│       ├── ADMINISTRATOR_GUIDE.md    # Operations guide
│       └── TROUBLESHOOTING_GUIDE.md  # Common issues
│
├── golden-paths/
│   ├── h1-basic/                     # H1 templates
│   ├── h2-enhanced/                  # H2 templates
│   └── h3-ai/                        # H3 templates
│
├── grafana/
│   └── dashboards/                   # Grafana JSON dashboards
│
├── policies/
│   ├── kubernetes/                   # Gatekeeper policies
│   └── terraform/                    # OPA policies for Terraform
│
├── prometheus/
│   ├── values.yaml                   # Helm values
│   ├── recording-rules.yaml          # Recording rules
│   └── alerting-rules.yaml           # Alert rules
│
├── scripts/
│   ├── bootstrap.sh                  # Main bootstrap script
│   ├── platform-bootstrap.sh         # Platform deployment
│   ├── validate-cli-prerequisites.sh # Prerequisites check
│   ├── validate-config.sh            # Config validation
│   ├── validate-deployment.sh        # Deployment verification
│   ├── validate-naming.sh            # Naming conventions
│   └── generate-platform-report.sh   # Status report
│
├── terraform/
│   ├── main.tf                       # Root module
│   ├── variables.tf                  # Variable definitions
│   ├── outputs.tf                    # Output definitions
│   ├── versions.tf                   # Provider versions
│   ├── terraform.tfvars.example      # Example configuration
│   └── modules/
│       ├── naming/                   # Naming conventions
│       ├── networking/               # VNet, subnets, NSGs
│       ├── aks-cluster/              # AKS configuration
│       ├── container-registry/       # ACR
│       ├── databases/                # PostgreSQL, Redis
│       ├── security/                 # Key Vault, identities
│       ├── defender/                 # Defender for Cloud
│       ├── purview/                  # Microsoft Purview
│       ├── observability/            # Azure Monitor
│       ├── argocd/                   # ArgoCD setup
│       ├── external-secrets/         # ESO configuration
│       ├── cost-management/          # Budgets, alerts
│       ├── disaster-recovery/        # DR configuration
│       └── ai-foundry/               # Azure OpenAI
│
└── tests/
    └── terraform/
        ├── go.mod                    # Go module
        └── modules/                  # Terratest files
            ├── naming_test.go
            ├── networking_test.go
            └── aks_cluster_test.go
```

---

## Appendix B: Environment Variables

### Required Variables

```bash
# Azure
export ARM_CLIENT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export ARM_CLIENT_SECRET="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export ARM_SUBSCRIPTION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export ARM_TENANT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# GitHub
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export GITHUB_ORG="your-organization"

# Project
export PROJECT_NAME="threehorizons"
export ENVIRONMENT="dev"
export AZURE_LOCATION="brazilsouth"
```

### Optional Variables

```bash
# Sizing
export SIZING_PROFILE="small"  # small, medium, large, xlarge

# Features
export ENABLE_H2="true"
export ENABLE_H3="false"
export ENABLE_DEFENDER="true"
export ENABLE_PURVIEW="true"
```

---

## Appendix C: Rollback Procedures

### Rollback H3 (AI Foundry)

```bash
cd terraform
terraform destroy -target=module.ai_foundry
sed -i 's/enable_h3 = true/enable_h3 = false/' terraform.tfvars
```

### Rollback H2 (Enhancement)

```bash
# Remove ArgoCD applications
kubectl delete applications --all -n argocd

# Remove namespaces
kubectl delete namespace argocd rhdh observability external-secrets gatekeeper-system

# Update tfvars
sed -i 's/enable_h2 = true/enable_h2 = false/' terraform.tfvars
terraform apply
```

### Rollback H1 (Full Destroy)

```bash
# WARNING: This destroys all resources!
cd terraform
terraform destroy

# Confirm with 'yes'
```

### Partial Rollback (Specific Module)

```bash
# Destroy only networking
terraform destroy -target=module.networking

# Re-apply
terraform apply
```

---

## Support

For issues or questions:
- GitHub Issues: [Create Issue](https://github.com/your-org/three-horizons-accelerator-v4/issues)
- Documentation: [/docs](../docs/)
- Slack: #platform-engineering

---

**Document Version:** 1.0.0
**Last Updated:** December 2025
**Maintainer:** Platform Engineering Team
