# Three Horizons Accelerator - Architecture Guide

> **Version:** 4.0.0
> **Last Updated:** December 2025

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Three Horizons Model](#2-three-horizons-model)
3. [Infrastructure Architecture](#3-infrastructure-architecture)
4. [Network Architecture](#4-network-architecture)
5. [Security Architecture](#5-security-architecture)
6. [GitOps Architecture](#6-gitops-architecture)
7. [Observability Architecture](#7-observability-architecture)
8. [AI/ML Architecture](#8-aiml-architecture)
9. [Agent Architecture](#9-agent-architecture)
10. [Data Flow Diagrams](#10-data-flow-diagrams)

---

## 1. Architecture Overview

### High-Level Platform Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           EXTERNAL LAYER                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Developers │  │   GitHub    │  │   Azure     │  │  External   │        │
│  │   (RHDH)    │  │  (CI/CD)    │  │   Portal    │  │    APIs     │        │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘        │
└─────────┼────────────────┼────────────────┼────────────────┼────────────────┘
          │                │                │                │
          ▼                ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           INGRESS LAYER                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    Azure Application Gateway                         │    │
│  │                    (WAF / SSL Termination)                          │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         KUBERNETES CLUSTER (AKS)                             │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         SYSTEM NAMESPACE                             │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐               │    │
│  │  │ CoreDNS  │ │ Metrics  │ │ Gatekeeper│ │  CSI    │               │    │
│  │  │          │ │ Server   │ │          │ │ Drivers  │               │    │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘               │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                      PLATFORM NAMESPACES                             │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐               │    │
│  │  │  ArgoCD  │ │   RHDH   │ │ External │ │Observ-   │               │    │
│  │  │          │ │          │ │ Secrets  │ │ability   │               │    │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘               │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    APPLICATION NAMESPACES                            │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐               │    │
│  │  │  App-A   │ │  App-B   │ │  App-C   │ │  App-N   │               │    │
│  │  │  (dev)   │ │ (staging)│ │  (prod)  │ │   ...    │               │    │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘               │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          AZURE PaaS SERVICES                                 │
│                                                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐         │
│  │   ACR    │ │Key Vault │ │PostgreSQL│ │  Redis   │ │ AI Foundry│         │
│  │          │ │          │ │ Flexible │ │  Cache   │ │ (OpenAI)  │         │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘         │
│                                                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐                       │
│  │ Defender │ │ Purview  │ │ Monitor  │ │ Storage  │                       │
│  │for Cloud │ │          │ │          │ │ Account  │                       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Design Principles

| Principle | Implementation |
|-----------|---------------|
| **Infrastructure as Code** | All resources defined in Terraform |
| **GitOps** | ArgoCD for declarative deployments |
| **Zero Trust** | Private endpoints, workload identity |
| **Immutable Infrastructure** | No manual changes to running systems |
| **Observable** | Metrics, logs, and traces for all components |
| **Self-Service** | Golden Path templates for developers |
| **Policy as Code** | Gatekeeper/OPA for enforcement |
| **Cost Awareness** | Budgets, alerts, right-sizing |

---

## 2. Three Horizons Model

### Horizon Overview

```
┌───────────────────────────────────────────────────────────────────────────┐
│                                                                           │
│   H3: INNOVATION                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐    │
│   │  AI/ML Capabilities    │  Experimental Features    │  Future    │    │
│   │  - Azure OpenAI        │  - Multi-agent systems    │  Platform  │    │
│   │  - MLOps pipelines     │  - Self-healing infra     │  Evolution │    │
│   │  - Intelligent agents  │  - Predictive scaling     │            │    │
│   └─────────────────────────────────────────────────────────────────┘    │
│                                                                           │
├───────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│   H2: ENHANCEMENT                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐    │
│   │  Developer Experience  │  Observability            │  GitOps    │    │
│   │  - RHDH Portal        │  - Prometheus/Grafana     │  - ArgoCD  │    │
│   │  - Golden Paths       │  - Alerting               │  - Flux    │    │
│   │  - Self-service       │  - Distributed tracing    │  - Kustomize│   │
│   └─────────────────────────────────────────────────────────────────┘    │
│                                                                           │
├───────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│   H1: FOUNDATION                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐    │
│   │  Compute              │  Networking               │  Security   │    │
│   │  - AKS Cluster        │  - VNet/Subnets           │  - Key Vault│    │
│   │  - Node Pools         │  - NSGs                   │  - Defender │    │
│   │  - ACR               │  - Private Endpoints      │  - Purview  │    │
│   └─────────────────────────────────────────────────────────────────┘    │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘
```

### H1: Foundation Components

| Component | Purpose | Azure Service | Terraform Module |
|-----------|---------|---------------|------------------|
| Compute | Container orchestration | AKS | `aks-cluster` |
| Registry | Container images | ACR | `container-registry` |
| Secrets | Secret management | Key Vault | `security` |
| Network | Connectivity | VNet | `networking` |
| Identity | Authentication | Managed Identity | `security` |
| Security | Threat protection | Defender | `defender` |
| Governance | Data catalog | Purview | `purview` |
| Database | Data persistence | PostgreSQL | `databases` |

### H2: Enhancement Components

| Component | Purpose | Technology | Terraform Module |
|-----------|---------|------------|------------------|
| GitOps | Declarative deployments | ArgoCD | `argocd` |
| Portal | Developer experience | RHDH | `rhdh` |
| Secrets Sync | External secrets | ESO | `external-secrets` |
| Monitoring | Metrics collection | Prometheus | `observability` |
| Dashboards | Visualization | Grafana | `observability` |
| Policies | Enforcement | Gatekeeper | `policies/` |
| Runners | CI/CD execution | GitHub Runners | `github-runners` |

### H3: Innovation Components

| Component | Purpose | Technology | Terraform Module |
|-----------|---------|------------|------------------|
| AI Models | LLM capabilities | Azure OpenAI | `ai-foundry` |
| Embeddings | Vector search | Text Embedding | `ai-foundry` |
| MLOps | ML lifecycle | ML Pipelines | `ai-foundry` |
| Agents | Intelligent automation | Custom Agents | `agents/` |

---

## 3. Infrastructure Architecture

### AKS Cluster Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           AKS CLUSTER                                        │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                      CONTROL PLANE (Azure Managed)                   │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐               │    │
│  │  │ API      │ │ etcd     │ │Controller│ │ Scheduler│               │    │
│  │  │ Server   │ │          │ │ Manager  │ │          │               │    │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘               │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         NODE POOLS                                   │    │
│  │                                                                      │    │
│  │  ┌────────────────────────────────────────────────────────────┐     │    │
│  │  │  SYSTEM NODE POOL (3 nodes, zones: 1,2,3)                  │     │    │
│  │  │  VM Size: Standard_D4s_v5 | OS: Ubuntu 22.04               │     │    │
│  │  │  Purpose: kube-system, platform components                  │     │    │
│  │  │  Taints: CriticalAddonsOnly=true:NoSchedule                │     │    │
│  │  └────────────────────────────────────────────────────────────┘     │    │
│  │                                                                      │    │
│  │  ┌────────────────────────────────────────────────────────────┐     │    │
│  │  │  USER NODE POOL (autoscale: 3-10, zones: 1,2,3)           │     │    │
│  │  │  VM Size: Standard_D8s_v5 | OS: Ubuntu 22.04               │     │    │
│  │  │  Purpose: Application workloads                            │     │    │
│  │  │  Labels: workload=general                                  │     │    │
│  │  └────────────────────────────────────────────────────────────┘     │    │
│  │                                                                      │    │
│  │  ┌────────────────────────────────────────────────────────────┐     │    │
│  │  │  GPU NODE POOL (autoscale: 0-5, zones: 1) - Optional      │     │    │
│  │  │  VM Size: Standard_NC6s_v3 | OS: Ubuntu 22.04              │     │    │
│  │  │  Purpose: AI/ML workloads                                  │     │    │
│  │  │  Taints: gpu=true:NoSchedule                               │     │    │
│  │  └────────────────────────────────────────────────────────────┘     │    │
│  │                                                                      │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         ADD-ONS                                      │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐               │    │
│  │  │ Azure    │ │ Key Vault│ │ Azure    │ │ Workload │               │    │
│  │  │ Policy   │ │ CSI      │ │ Monitor  │ │ Identity │               │    │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘               │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### AKS Configuration Details

```hcl
# terraform/modules/aks-cluster/main.tf

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.customer_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-${var.customer_name}-${var.environment}"
  kubernetes_version  = var.kubernetes_version  # 1.29
  sku_tier            = var.sku_tier            # Standard

  default_node_pool {
    name                = "system"
    vm_size             = "Standard_D4s_v5"
    node_count          = 3
    zones               = ["1", "2", "3"]
    vnet_subnet_id      = var.vnet_subnet_id
    enable_auto_scaling = false

    only_critical_addons_enabled = true
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.aks_identity_id]
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    load_balancer_sku   = "standard"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  azure_policy_enabled = true

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }
}
```

---

## 4. Network Architecture

### Network Topology

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        VIRTUAL NETWORK: 10.0.0.0/16                          │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  AKS NODES SUBNET: 10.0.0.0/22 (1024 IPs)                             │  │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │  │
│  │  │  NSG: nsg-aks-nodes                                             │  │  │
│  │  │  - Allow: AKS API Server (443)                                  │  │  │
│  │  │  - Allow: Internal VNet traffic                                 │  │  │
│  │  │  - Deny: All other inbound                                      │  │  │
│  │  └─────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  AKS PODS SUBNET: 10.0.16.0/20 (4096 IPs) - Azure CNI Overlay        │  │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │  │
│  │  │  Pod CIDR: 10.244.0.0/16 (Overlay)                              │  │  │
│  │  └─────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  PRIVATE ENDPOINTS SUBNET: 10.0.4.0/24 (256 IPs)                      │  │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │  │
│  │  │  Private Endpoints:                                             │  │  │
│  │  │  - Key Vault: pe-kv-threehorizons-dev                          │  │  │
│  │  │  - ACR: pe-acr-threehorizons-dev                               │  │  │
│  │  │  - PostgreSQL: pe-psql-threehorizons-dev                       │  │  │
│  │  │  - AI Foundry: pe-ai-threehorizons-dev                         │  │  │
│  │  └─────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  AZURE BASTION SUBNET: 10.0.5.0/26 (64 IPs) - AzureBastionSubnet     │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  APP GATEWAY SUBNET: 10.0.6.0/24 (256 IPs)                            │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Private DNS Zones

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PRIVATE DNS ZONES                                    │
│                                                                              │
│  Zone                                    │ Purpose                           │
│  ────────────────────────────────────────┼────────────────────────────────── │
│  privatelink.vaultcore.azure.net         │ Key Vault                         │
│  privatelink.azurecr.io                  │ Container Registry                │
│  privatelink.postgres.database.azure.com │ PostgreSQL                        │
│  privatelink.redis.cache.windows.net     │ Redis Cache                       │
│  privatelink.openai.azure.com            │ Azure OpenAI                      │
│  privatelink.blob.core.windows.net       │ Storage Account                   │
│  privatelink.monitor.azure.com           │ Azure Monitor                     │
│                                                                              │
│  All zones linked to: vnet-threehorizons-dev                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Network Security Groups

```yaml
# NSG: nsg-aks-nodes
rules:
  - name: AllowHTTPS
    priority: 100
    direction: Inbound
    access: Allow
    protocol: Tcp
    source: VirtualNetwork
    destination: "*"
    destination_port: 443

  - name: AllowKubelet
    priority: 110
    direction: Inbound
    access: Allow
    protocol: Tcp
    source: VirtualNetwork
    destination: "*"
    destination_port: 10250

  - name: DenyAllInbound
    priority: 4096
    direction: Inbound
    access: Deny
    protocol: "*"
    source: "*"
    destination: "*"
    destination_port: "*"

# NSG: nsg-private-endpoints
rules:
  - name: AllowVNetInbound
    priority: 100
    direction: Inbound
    access: Allow
    protocol: "*"
    source: VirtualNetwork
    destination: "*"
    destination_port: "*"

  - name: DenyAllInbound
    priority: 4096
    direction: Inbound
    access: Deny
    protocol: "*"
    source: "*"
    destination: "*"
    destination_port: "*"
```

---

## 5. Security Architecture

### Zero Trust Model

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ZERO TRUST LAYERS                                  │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  IDENTITY LAYER                                                      │    │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐                │    │
│  │  │ Entra ID     │ │ Workload     │ │ Managed      │                │    │
│  │  │ (Azure AD)   │ │ Identity     │ │ Identity     │                │    │
│  │  │              │ │ Federation   │ │              │                │    │
│  │  └──────────────┘ └──────────────┘ └──────────────┘                │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  NETWORK LAYER                                                       │    │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐                │    │
│  │  │ Private      │ │ NSG Rules    │ │ Network      │                │    │
│  │  │ Endpoints    │ │              │ │ Policies     │                │    │
│  │  └──────────────┘ └──────────────┘ └──────────────┘                │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  DATA LAYER                                                          │    │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐                │    │
│  │  │ Encryption   │ │ Key Vault    │ │ Purview      │                │    │
│  │  │ at Rest/     │ │ Secrets      │ │ Classification│               │    │
│  │  │ Transit      │ │              │ │              │                │    │
│  │  └──────────────┘ └──────────────┘ └──────────────┘                │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  APPLICATION LAYER                                                   │    │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐                │    │
│  │  │ Gatekeeper   │ │ Azure Policy │ │ Defender     │                │    │
│  │  │ Constraints  │ │              │ │ for Cloud    │                │    │
│  │  └──────────────┘ └──────────────┘ └──────────────┘                │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Workload Identity Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Kubernetes  │     │    OIDC      │     │   Entra ID   │     │  Azure       │
│  Pod         │────▶│   Issuer     │────▶│   (Token     │────▶│  Resource    │
│              │     │   (AKS)      │     │   Exchange)  │     │  (Key Vault) │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
       │                                          │
       │                                          │
       ▼                                          ▼
┌──────────────┐                          ┌──────────────┐
│ Service      │                          │ Federated    │
│ Account      │                          │ Credential   │
│ Token        │                          │              │
└──────────────┘                          └──────────────┘

Flow:
1. Pod requests token from Kubernetes API
2. AKS OIDC issuer provides JWT token
3. Token exchanged with Entra ID for Azure access token
4. Access token used to authenticate to Azure services
```

### Defender for Cloud Integration

```yaml
# Defender Coverage
defender_for_cloud:
  plans:
    - name: Defender for Containers
      enabled: true
      features:
        - runtime_protection
        - vulnerability_assessment
        - kubernetes_audit_logs

    - name: Defender for Key Vault
      enabled: true
      features:
        - threat_detection
        - access_anomaly_detection

    - name: Defender for Storage
      enabled: true
      features:
        - malware_scanning
        - sensitive_data_threat_detection

    - name: Defender for Databases
      enabled: true
      features:
        - vulnerability_assessment
        - advanced_threat_protection

  regulatory_compliance:
    - LGPD (Brazil)
    - SOC 2
    - ISO 27001
```

---

## 6. GitOps Architecture

### ArgoCD Application Hierarchy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ARGOCD APPLICATION STRUCTURE                         │
│                                                                              │
│                        ┌──────────────────────┐                              │
│                        │    app-of-apps       │                              │
│                        │    (Wave: 0)         │                              │
│                        └──────────┬───────────┘                              │
│                                   │                                          │
│              ┌────────────────────┼────────────────────┐                    │
│              │                    │                    │                    │
│              ▼                    ▼                    ▼                    │
│  ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐            │
│  │ external-secrets │ │   gatekeeper     │ │  observability   │            │
│  │   (Wave: 1)      │ │   (Wave: 2)      │ │   (Wave: 3)      │            │
│  └──────────────────┘ └──────────────────┘ └──────────────────┘            │
│                                   │                                          │
│              ┌────────────────────┼────────────────────┐                    │
│              │                    │                    │                    │
│              ▼                    ▼                    ▼                    │
│  ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐            │
│  │      rhdh        │ │  github-runners  │ │  cost-management │            │
│  │   (Wave: 4)      │ │   (Wave: 4)      │ │   (Wave: 4)      │            │
│  └──────────────────┘ └──────────────────┘ └──────────────────┘            │
│                                   │                                          │
│                                   ▼                                          │
│                       ┌──────────────────┐                                  │
│                       │  ApplicationSets │                                  │
│                       │   (Wave: 5)      │                                  │
│                       └──────────────────┘                                  │
│                                   │                                          │
│              ┌────────────────────┼────────────────────┐                    │
│              │                    │                    │                    │
│              ▼                    ▼                    ▼                    │
│  ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐            │
│  │   app-dev-*      │ │  app-staging-*   │ │   app-prod-*     │            │
│  └──────────────────┘ └──────────────────┘ └──────────────────┘            │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Sync Waves Explained

| Wave | Components | Purpose |
|------|------------|---------|
| **0** | App-of-Apps | Bootstrap entry point |
| **1** | External Secrets | Secret management must be first |
| **2** | Gatekeeper | Policy enforcement before apps |
| **3** | Observability | Monitoring for all subsequent apps |
| **4** | RHDH, Runners | Platform tools |
| **5** | ApplicationSets | Dynamic application generation |

### Repository Structure for GitOps

```
argocd/
├── apps/
│   ├── app-of-apps.yaml           # Root application
│   ├── external-secrets.yaml      # ESO deployment
│   ├── gatekeeper.yaml            # Policy deployment
│   ├── observability.yaml         # Prometheus/Grafana
│   └── rhdh.yaml                  # Developer portal
│
├── applicationsets/
│   ├── microservices.yaml         # Generate apps for microservices
│   └── environments.yaml          # Generate per-environment apps
│
├── base/
│   ├── namespace.yaml             # Common namespace definition
│   └── network-policy.yaml        # Common network policies
│
├── overlays/
│   ├── dev/
│   │   └── kustomization.yaml
│   ├── staging/
│   │   └── kustomization.yaml
│   └── prod/
│       └── kustomization.yaml
│
├── secrets/
│   ├── cluster-secret-store.yaml  # Azure Key Vault connection
│   └── external-secrets/          # ExternalSecret definitions
│
├── argocd-cm.yaml                 # ArgoCD configuration
├── argocd-rbac-cm.yaml            # RBAC configuration
└── notifications.yaml             # Notification configuration
```

---

## 7. Observability Architecture

### Metrics Pipeline

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        OBSERVABILITY ARCHITECTURE                            │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         COLLECTION LAYER                             │    │
│  │                                                                      │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │    │
│  │  │  Prometheus  │  │  Node        │  │  cAdvisor    │              │    │
│  │  │  Scraping    │  │  Exporter    │  │              │              │    │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘              │    │
│  │         │                 │                 │                       │    │
│  │         └─────────────────┴─────────────────┘                       │    │
│  │                           │                                         │    │
│  └───────────────────────────┼─────────────────────────────────────────┘    │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         STORAGE LAYER                                │    │
│  │                                                                      │    │
│  │  ┌─────────────────────────────────────────────────────────────┐    │    │
│  │  │              Azure Managed Prometheus                        │    │    │
│  │  │              (15 days retention)                             │    │    │
│  │  └─────────────────────────────────────────────────────────────┘    │    │
│  │                              │                                       │    │
│  └──────────────────────────────┼──────────────────────────────────────┘    │
│                                 ▼                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                      VISUALIZATION LAYER                             │    │
│  │                                                                      │    │
│  │  ┌─────────────────────────────────────────────────────────────┐    │    │
│  │  │              Azure Managed Grafana                           │    │    │
│  │  │                                                              │    │    │
│  │  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │    │    │
│  │  │  │ Platform │ │ Agent    │ │ Cost     │ │ Custom   │       │    │    │
│  │  │  │ Overview │ │ Metrics  │ │ Dashboard│ │ Dashboards│       │    │    │
│  │  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │    │    │
│  │  │                                                              │    │    │
│  │  └─────────────────────────────────────────────────────────────┘    │    │
│  │                                                                      │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         ALERTING LAYER                               │    │
│  │                                                                      │    │
│  │  ┌──────────────┐        ┌──────────────┐        ┌──────────────┐  │    │
│  │  │ Alert        │───────▶│ Alert        │───────▶│ Notifications│  │    │
│  │  │ Rules        │        │ Manager      │        │ (Teams/Slack)│  │    │
│  │  └──────────────┘        └──────────────┘        └──────────────┘  │    │
│  │                                                                      │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Key Metrics

```yaml
# Platform Metrics
platform_metrics:
  - name: cluster_health
    query: sum(kube_node_status_condition{condition="Ready",status="true"})
    threshold: 3

  - name: pod_availability
    query: sum(kube_pod_status_ready) / sum(kube_pod_status_phase{phase="Running"})
    threshold: 0.99

  - name: api_server_latency
    query: histogram_quantile(0.99, rate(apiserver_request_duration_seconds_bucket[5m]))
    threshold: 1.0

# Application Metrics
application_metrics:
  - name: request_rate
    query: sum(rate(http_requests_total[5m]))

  - name: error_rate
    query: sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))
    threshold: 0.01

  - name: latency_p99
    query: histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
    threshold: 0.5
```

---

## 8. AI/ML Architecture

### AI Foundry Integration

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AI FOUNDRY ARCHITECTURE                              │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                      AZURE OPENAI SERVICE                            │    │
│  │                                                                      │    │
│  │  ┌──────────────────────────────────────────────────────────────┐   │    │
│  │  │  MODEL DEPLOYMENTS                                            │   │    │
│  │  │                                                               │   │    │
│  │  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │   │    │
│  │  │  │  gpt-4o     │ │ gpt-4o-mini │ │text-embedding│            │   │    │
│  │  │  │             │ │             │ │ -3-large    │            │   │    │
│  │  │  │ Capacity: 10│ │ Capacity: 20│ │ Capacity: 50│            │   │    │
│  │  │  │ TPM: 10K    │ │ TPM: 20K    │ │ TPM: 50K    │            │   │    │
│  │  │  └─────────────┘ └─────────────┘ └─────────────┘            │   │    │
│  │  │                                                               │   │    │
│  │  └──────────────────────────────────────────────────────────────┘   │    │
│  │                              │                                       │    │
│  └──────────────────────────────┼──────────────────────────────────────┘    │
│                                 │                                            │
│                                 ▼                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                     PRIVATE ENDPOINT                                 │    │
│  │                   pe-ai-threehorizons-dev                           │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                 │                                            │
│                                 ▼                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                     KUBERNETES INTEGRATION                           │    │
│  │                                                                      │    │
│  │  ┌─────────────────┐     ┌─────────────────┐                        │    │
│  │  │ ExternalSecret  │────▶│ K8s Secret      │                        │    │
│  │  │ (AI API Key)    │     │ (ai-credentials)│                        │    │
│  │  └─────────────────┘     └────────┬────────┘                        │    │
│  │                                   │                                  │    │
│  │                                   ▼                                  │    │
│  │  ┌─────────────────────────────────────────────────────────────┐    │    │
│  │  │  APPLICATION PODS                                            │    │    │
│  │  │                                                              │    │    │
│  │  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐         │    │    │
│  │  │  │ AI Agent     │ │ Chatbot      │ │ Document     │         │    │    │
│  │  │  │ Service      │ │ Service      │ │ Processing   │         │    │    │
│  │  │  └──────────────┘ └──────────────┘ └──────────────┘         │    │    │
│  │  │                                                              │    │    │
│  │  └─────────────────────────────────────────────────────────────┘    │    │
│  │                                                                      │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Model Selection Guide

| Model | Use Case | Tokens/min | Cost |
|-------|----------|------------|------|
| **gpt-4o** | Complex reasoning, coding | 10K | $$$ |
| **gpt-4o-mini** | General chat, simple tasks | 20K | $ |
| **text-embedding-3-large** | Semantic search, RAG | 50K | $ |
| **text-embedding-3-small** | Basic embeddings | 100K | $ |

### LATAM AI Strategy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     LATAM AI DEPLOYMENT PATTERN                              │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                     BRAZIL SOUTH (Primary)                           │    │
│  │                                                                      │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │    │
│  │  │ AKS Cluster  │  │ PostgreSQL   │  │ Key Vault    │              │    │
│  │  │ (Workloads)  │  │ (Data - LGPD)│  │ (Secrets)    │              │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘              │    │
│  │                         │                                           │    │
│  │                         │ Data stays in Brazil                      │    │
│  │                         ▼                                           │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              │ Private Link (Secure)                        │
│                              │                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                     EAST US 2 (AI Processing)                        │    │
│  │                                                                      │    │
│  │  ┌─────────────────────────────────────────────────────────────┐    │    │
│  │  │  Azure OpenAI                                                │    │    │
│  │  │  - gpt-4o (Full capabilities)                               │    │    │
│  │  │  - o3-mini (Reasoning)                                       │    │    │
│  │  │  - Full model catalog                                        │    │    │
│  │  └─────────────────────────────────────────────────────────────┘    │    │
│  │                                                                      │    │
│  │  Note: Only prompts/responses traverse regions                      │    │
│  │        Customer data stays in Brazil South                          │    │
│  │                                                                      │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 9. Agent Architecture

### Agent Orchestration Model

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AGENT ARCHITECTURE                                   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                     ORCHESTRATION LAYER                              │    │
│  │                                                                      │    │
│  │                 ┌──────────────────────┐                            │    │
│  │                 │  Platform            │                            │    │
│  │                 │  Orchestrator        │                            │    │
│  │                 │  Agent               │                            │    │
│  │                 └──────────┬───────────┘                            │    │
│  │                            │                                         │    │
│  └────────────────────────────┼────────────────────────────────────────┘    │
│                               │                                              │
│           ┌───────────────────┼───────────────────┐                         │
│           │                   │                   │                         │
│           ▼                   ▼                   ▼                         │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐               │
│  │  H1 FOUNDATION  │ │ H2 ENHANCEMENT  │ │  H3 INNOVATION  │               │
│  │     AGENTS      │ │     AGENTS      │ │     AGENTS      │               │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘               │
│           │                   │                   │                         │
│  ┌────────┴────────┐ ┌───────┴───────┐ ┌────────┴────────┐                │
│  │ infrastructure  │ │ gitops-agent  │ │ ai-foundry-agent│                │
│  │ networking      │ │ rhdh-portal   │ │ mlops-pipeline  │                │
│  │ database        │ │ golden-paths  │ │ sre-agent       │                │
│  │ security        │ │ observability │ │ multi-agent     │                │
│  │ defender        │ │ github-runners│ │                 │                │
│  │ purview         │ │               │ │                 │                │
│  │ container-reg   │ │               │ │                 │                │
│  │ aro-platform    │ │               │ │                 │                │
│  └─────────────────┘ └───────────────┘ └─────────────────┘                │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                     CROSS-CUTTING AGENTS                             │    │
│  │                                                                      │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │    │
│  │  │ github-  │ │ identity-│ │validation│ │migration │ │ rollback │  │    │
│  │  │ app      │ │ federat  │ │          │ │          │ │          │  │    │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘  │    │
│  │                                                                      │    │
│  │  ┌──────────┐                                                        │    │
│  │  │ cost-    │                                                        │    │
│  │  │ optimiz  │                                                        │    │
│  │  └──────────┘                                                        │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Agent Communication Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   GitHub     │     │    Agent     │     │   Terraform  │     │    Azure     │
│   Issue      │────▶│   Service    │────▶│   Execution  │────▶│   Resources  │
│              │     │              │     │              │     │              │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
       │                    │                    │                    │
       │                    ▼                    │                    │
       │           ┌──────────────┐              │                    │
       │           │   MCP        │              │                    │
       │           │   Servers    │              │                    │
       │           │              │              │                    │
       │           └──────────────┘              │                    │
       │                    │                    │                    │
       ▼                    ▼                    ▼                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                            AUDIT LOG                                      │
│  - Issue created                                                          │
│  - Agent triggered                                                        │
│  - Terraform planned                                                      │
│  - Resources created                                                      │
│  - Status updated                                                         │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 10. Data Flow Diagrams

### Application Deployment Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     APPLICATION DEPLOYMENT FLOW                              │
│                                                                              │
│  ┌──────────┐                                                               │
│  │Developer │                                                               │
│  └────┬─────┘                                                               │
│       │                                                                      │
│       │ 1. Create from Golden Path                                          │
│       ▼                                                                      │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐                            │
│  │   RHDH   │────▶│  GitHub  │────▶│  CI/CD   │                            │
│  │  Portal  │     │   Repo   │     │ Workflow │                            │
│  └──────────┘     └──────────┘     └────┬─────┘                            │
│                                         │                                    │
│       ┌─────────────────────────────────┼─────────────────────────────┐     │
│       │                                 │                             │     │
│       ▼                                 ▼                             ▼     │
│  ┌──────────┐                     ┌──────────┐                  ┌──────────┐│
│  │  Build   │                     │   Test   │                  │  Scan    ││
│  │  Image   │                     │          │                  │ Security ││
│  └────┬─────┘                     └────┬─────┘                  └────┬─────┘│
│       │                                │                             │      │
│       └────────────────────────────────┴─────────────────────────────┘      │
│                                         │                                    │
│                                         │ 2. Push to ACR                    │
│                                         ▼                                    │
│                                    ┌──────────┐                             │
│                                    │   ACR    │                             │
│                                    └────┬─────┘                             │
│                                         │                                    │
│                                         │ 3. Image available                │
│                                         ▼                                    │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐                            │
│  │  ArgoCD  │◀────│ GitOps   │◀────│ Git Push │                            │
│  │          │     │   Repo   │     │ (k8s     │                            │
│  │          │     │          │     │ manifests)                            │
│  └────┬─────┘     └──────────┘     └──────────┘                            │
│       │                                                                      │
│       │ 4. Sync to cluster                                                  │
│       ▼                                                                      │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                          AKS CLUSTER                                  │   │
│  │                                                                       │   │
│  │  ┌──────────┐     ┌──────────┐     ┌──────────┐                      │   │
│  │  │ Gatekeeper│────▶│  Deploy  │────▶│   Pod    │                      │   │
│  │  │ (Validate)│     │          │     │ Running  │                      │   │
│  │  └──────────┘     └──────────┘     └──────────┘                      │   │
│  │                                                                       │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Secret Management Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     SECRET MANAGEMENT FLOW                                   │
│                                                                              │
│  ┌──────────────┐                                                           │
│  │ Azure Key    │                                                           │
│  │ Vault        │                                                           │
│  │              │                                                           │
│  │ Secrets:     │                                                           │
│  │ - db-password│                                                           │
│  │ - api-key    │                                                           │
│  │ - tls-cert   │                                                           │
│  └──────┬───────┘                                                           │
│         │                                                                    │
│         │ 1. Workload Identity                                              │
│         │    Authentication                                                  │
│         ▼                                                                    │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                    EXTERNAL SECRETS OPERATOR                          │   │
│  │                                                                       │   │
│  │  ┌──────────────┐                                                     │   │
│  │  │ ClusterSecret│  2. Poll Key Vault                                  │   │
│  │  │ Store        │     (every 1h)                                      │   │
│  │  │              │                                                     │   │
│  │  │ Provider:    │                                                     │   │
│  │  │ Azure KV     │                                                     │   │
│  │  └──────────────┘                                                     │   │
│  │          │                                                            │   │
│  │          │                                                            │   │
│  │          ▼                                                            │   │
│  │  ┌──────────────┐     ┌──────────────┐                               │   │
│  │  │ External     │────▶│ Kubernetes   │  3. Create/Update             │   │
│  │  │ Secret       │     │ Secret       │     K8s Secret                 │   │
│  │  │              │     │              │                                │   │
│  │  │ Mapping:     │     │ Data:        │                                │   │
│  │  │ db-password  │     │ password=*** │                                │   │
│  │  └──────────────┘     └──────┬───────┘                               │   │
│  │                              │                                        │   │
│  └──────────────────────────────┼────────────────────────────────────────┘   │
│                                 │                                            │
│                                 │ 4. Mount as volume                        │
│                                 │    or env var                              │
│                                 ▼                                            │
│                          ┌──────────────┐                                   │
│                          │ Application  │                                   │
│                          │ Pod          │                                   │
│                          │              │                                   │
│                          │ env:         │                                   │
│                          │ DB_PASSWORD  │                                   │
│                          └──────────────┘                                   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Summary

This architecture provides:

1. **Layered Approach**: Clear separation between Foundation (H1), Enhancement (H2), and Innovation (H3)
2. **Security First**: Zero trust, private endpoints, workload identity
3. **GitOps Native**: ArgoCD for all deployments
4. **Observable**: Full metrics and logging pipeline
5. **AI Ready**: Azure OpenAI integration with LATAM strategy
6. **Self-Service**: Golden Paths for developers
7. **Policy Driven**: Gatekeeper for enforcement
8. **Cost Aware**: Budgets and right-sizing built-in

---

**Document Version:** 1.0.0
**Last Updated:** December 2025
**Maintainer:** Platform Engineering Team
