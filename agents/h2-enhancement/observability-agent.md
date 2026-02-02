---
name: "Observability Agent"
version: "2.0.0"
horizon: "H2"
status: "stable"
last_updated: "2026-02-02"
skills:
  - kubectl-cli
  - helm-cli
  - azure-cli
  - validation-scripts
dependencies:
  - infrastructure-agent
  - gitops-agent
---

# Observability Agent

## ⚠️ Explicit Consent Required

**User Consent Prompt:**
```markdown
📊 **Observability Stack Deployment Request**

This action will:
- ✅ Install Prometheus (metrics collection)
- ✅ Install Grafana (visualization dashboards)
- ✅ Install Alertmanager (alert routing)
- ✅ Install Loki (log aggregation)
- ✅ Create persistent volumes (storage costs apply)
- ⚠️ Storage requirements: 50Gi-200Gi (PVs)

**Resources Required:**
- Namespace: monitoring
- Persistent Volumes: ~3-5 PVs
- Memory: ~8-16 GB total
- CPU: ~4-8 cores total

**Configuration:**
- Prometheus Retention: ${RETENTION_DAYS} days
- Grafana Admin Password: ${GRAFANA_PASSWORD}
- Alert Notifications: ${NOTIFICATION_CHANNELS}

Type **"approve:observability"** to proceed or **"reject"** to cancel.
```

**Approval Format:** `approve:observability retention={days} notifications={channels}`

## 🤖 Agent Identity

```yaml
name: observability-agent
version: 1.0.0
horizon: H2 - Enhancement
description: |
  Deploys and configures the observability stack on AKS.
  Installs Prometheus, Grafana, Alertmanager, and Loki.
  Creates dashboards, alerts, and notification channels.
  
author: Microsoft LATAM Platform Engineering
model_compatibility:
  - GitHub Copilot Agent Mode
  - GitHub Copilot Coding Agent
  - Claude with MCP
```

---

## 📁 Terraform Module
**Primary Module:** `terraform/modules/observability/main.tf`

## 📋 Related Resources
| Resource Type | Path |
|--------------|------|
| Terraform Module | `terraform/modules/observability/main.tf` |
| Issue Template | `.github/ISSUE_TEMPLATE/observability.yml` |
| Grafana Dashboard | `grafana/dashboards/golden-path-application.json` |
| Prometheus Rules | `prometheus/alerting-rules.yaml` |
| Sizing Config | `config/sizing-profiles.yaml` |

---

## 🎯 Capabilities

| Capability | Description | Complexity |
|------------|-------------|------------|
| **Install Prometheus** | Deploy Prometheus via Helm | Medium |
| **Install Grafana** | Deploy Grafana with dashboards | Medium |
| **Install Alertmanager** | Configure alert routing | Low |
| **Install Loki** | Deploy log aggregation | Medium |
| **Create Dashboards** | Import/create Grafana dashboards | Low |
| **Configure Alerts** | Setup Prometheus alert rules | Low |
| **Configure Notifications** | Teams, Slack, PagerDuty | Low |
| **Enable Azure Monitor** | Azure-native integration | Medium |

---

## 🔧 MCP Servers Required

```json
{
  "mcpServers": {
    "kubernetes": {
      "required": true,
      "capabilities": ["kubectl apply", "kubectl get", "helm install"]
    },
    "helm": {
      "required": true,
      "capabilities": ["helm repo add", "helm install", "helm upgrade"]
    },
    "github": {
      "required": true
    },
    "filesystem": {
      "required": true
    }
  }
}
```

---

## 🏷️ Trigger Labels

```yaml
primary_label: "agent:observability"
required_labels:
  - horizon:h2
environment_labels:
  - env:dev
  - env:staging
  - env:prod
```

---

## 📋 Issue Template

```markdown
---
title: "[H2] Setup Observability - {PROJECT_NAME}"
labels: agent:observability, horizon:h2, env:dev
---

## Configuration

```yaml
observability:
  prometheus:
    enabled: true
    retention: "15d"
    storage_size: "50Gi"
    
  grafana:
    enabled: true
    admin_password: "${GRAFANA_ADMIN_PASSWORD}"
    dashboards:
      - kubernetes-cluster
      - node-exporter
      - argocd
      - aks-monitoring
      - ai-apps
      
  alertmanager:
    enabled: true
    routes:
      - match:
          severity: critical
        receiver: pagerduty
      - match:
          severity: warning
        receiver: teams
        
  loki:
    enabled: true
    retention: "7d"
    
  notifications:
    teams:
      enabled: true
      webhook_url: ""
    slack:
      enabled: false
    pagerduty:
      enabled: false
```

## Acceptance Criteria
- [ ] Prometheus running and scraping targets
- [ ] Grafana accessible with dashboards
- [ ] Alertmanager configured
- [ ] Test alert fires correctly
```

---

## 🛠️ Installation Commands

```bash
# Add Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create namespace
kubectl create namespace monitoring

# Install kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus-values.yaml \
  --wait --timeout 10m

# Install Loki
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --values loki-values.yaml \
  --wait

# Verify
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

---

## 📊 Pre-configured Dashboards

| Dashboard | ID | Description |
|-----------|-----|-------------|
| Kubernetes Cluster | 7249 | Cluster overview |
| Node Exporter | 1860 | Node metrics |
| ArgoCD | 14584 | ArgoCD monitoring |
| AKS Monitoring | 18283 | Azure AKS specific |
| AI Applications | Custom | AI/ML workloads |

---

## 🔔 Alert Rules Included

| Alert | Severity | Description |
|-------|----------|-------------|
| `HighCPUUsage` | warning | Node CPU > 80% |
| `HighMemoryUsage` | warning | Node Memory > 85% |
| `PodCrashLooping` | critical | Pod restart > 5 |
| `DeploymentReplicasMismatch` | warning | Replicas != desired |
| `PersistentVolumeFillingUp` | warning | PV > 85% full |
| `KubeAPILatency` | warning | API latency > 1s |

---

## 📐 Sizing Profiles

### Small (< 10 nodes)
```yaml
prometheus:
  retention: 7d
  storage_size: 30Gi
  memory: 2Gi
  cpu: 1000m

grafana:
  memory: 512Mi
  cpu: 250m

loki:
  retention: 3d
  storage_size: 20Gi
```

### Medium (10-50 nodes)
```yaml
prometheus:
  retention: 15d
  storage_size: 50Gi
  memory: 4Gi
  cpu: 2000m

grafana:
  memory: 1Gi
  cpu: 500m

loki:
  retention: 7d
  storage_size: 50Gi
```

### Large (50-200 nodes)
```yaml
prometheus:
  retention: 30d
  storage_size: 100Gi
  memory: 8Gi
  cpu: 4000m

grafana:
  memory: 2Gi
  cpu: 1000m

loki:
  retention: 15d
  storage_size: 100Gi
```

### XLarge (200+ nodes)
```yaml
prometheus:
  retention: 45d
  storage_size: 200Gi
  memory: 16Gi
  cpu: 8000m
  high_availability: true
  replicas: 2

grafana:
  memory: 4Gi
  cpu: 2000m
  replicas: 2

loki:
  retention: 30d
  storage_size: 200Gi
  replicas: 3
```

---

## 🔗 Azure Monitor Integration

```bash
# Enable Azure Monitor managed service for Prometheus
az aks enable-addons \
  --resource-group ${RESOURCE_GROUP} \
  --name ${AKS_CLUSTER} \
  --addons monitoring \
  --workspace-resource-id ${LOG_ANALYTICS_ID}

# Enable managed Grafana
az grafana create \
  --name ${PROJECT}-grafana \
  --resource-group ${RESOURCE_GROUP} \
  --location ${LOCATION}

# Link Prometheus to Grafana
az grafana data-source create \
  --name ${PROJECT}-grafana \
  --definition '{"type":"prometheus","url":"https://eus.prometheus.monitor.azure.com"}'
```

---

## 🔄 GitHub Actions Workflow

**Workflow File:** `.github/workflows/observability-deploy.yml`

```yaml
name: Deploy Observability Stack

on:
  issues:
    types: [labeled]
  workflow_dispatch:
    inputs:
      sizing_profile:
        description: 'Sizing profile'
        required: true
        type: choice
        options:
          - small
          - medium
          - large
          - xlarge

permissions:
  id-token: write
  contents: read
  issues: write

jobs:
  deploy-observability:
    runs-on: ubuntu-latest
    if: |
      (github.event_name == 'issues' && contains(github.event.issue.labels.*.name, 'agent:observability') && contains(github.event.issue.labels.*.name, 'approved')) ||
      (github.event_name == 'workflow_dispatch')
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Parse issue configuration
        if: github.event_name == 'issues'
        id: parse
        uses: stefanbuck/github-issue-parser@v3
        with:
          template-path: .github/ISSUE_TEMPLATE/observability.yml
      
      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Get AKS credentials
        run: |
          if [[ "${{ github.event_name }}" == "workflow_dispatch" ]]; then
            CLUSTER_NAME=${{ secrets.AKS_CLUSTER_NAME }}
            RG_NAME=${{ secrets.RESOURCE_GROUP }}
          else
            CLUSTER_NAME=${{ fromJson(steps.parse.outputs.jsonString).aks_cluster }}
            RG_NAME=${{ fromJson(steps.parse.outputs.jsonString).resource_group }}
          fi
          az aks get-credentials --resource-group $RG_NAME --name $CLUSTER_NAME --overwrite-existing
      
      - name: Create monitoring namespace
        run: kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
      
      - name: Add Helm repositories
        run: |
          helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
          helm repo add grafana https://grafana.github.io/helm-charts
          helm repo update
      
      - name: Install Prometheus Stack
        run: |
          helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
            --namespace monitoring \
            --set prometheus.prometheusSpec.retention=15d \
            --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi \
            --set grafana.adminPassword=${{ secrets.GRAFANA_ADMIN_PASSWORD }} \
            --wait --timeout 15m
      
      - name: Install Loki
        run: |
          helm upgrade --install loki grafana/loki-stack \
            --namespace monitoring \
            --set loki.persistence.enabled=true \
            --set loki.persistence.size=50Gi \
            --wait --timeout 10m
      
      - name: Import Grafana dashboards
        run: |
          kubectl apply -f grafana/dashboards/ -n monitoring
      
      - name: Apply Prometheus alert rules
        run: |
          kubectl apply -f prometheus/alerting-rules.yaml -n monitoring
      
      - name: Validate deployment
        run: |
          kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=300s
          kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s
          echo "✅ Prometheus and Grafana are running"
      
      - name: Get Grafana URL
        if: success()
        run: |
          GRAFANA_IP=$(kubectl get svc -n monitoring prometheus-grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
          echo "GRAFANA_URL=http://${GRAFANA_IP}" >> $GITHUB_ENV
      
      - name: Comment success on issue
        if: github.event_name == 'issues' && success()
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `✅ **Observability Stack Deployed Successfully**\n\n**Components:**\n- Prometheus: ✅ Running\n- Grafana: ✅ Running\n- Alertmanager: ✅ Running\n- Loki: ✅ Running\n\n**Access:**\n- Grafana URL: ${process.env.GRAFANA_URL}\n- Admin user: admin\n- Password: (stored in Key Vault)\n\n📊 Check dashboards in Grafana!`
            })
      
      - name: Close issue
        if: github.event_name == 'issues' && success()
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.update({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              state: 'closed',
              labels: ['completed']
            })
```

**Trigger:** Label issue with `agent:observability` + `approved`

---

## ✅ Validation Criteria
- [ ] Prometheus running and scraping targets
- [ ] Grafana accessible with dashboards
- [ ] Alertmanager configured and routing alerts
- [ ] Loki ingesting logs
- [ ] At least 5 dashboards imported
- [ ] Test alert fires correctly
- [ ] Azure Monitor integration (optional)

---

**Spec Version:** 1.0.0
