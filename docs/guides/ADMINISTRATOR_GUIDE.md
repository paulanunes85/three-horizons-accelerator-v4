# Three Horizons Accelerator - Administrator Guide

> **Version:** 4.0.0
> **Last Updated:** December 2025

---

## Table of Contents

1. [Daily Operations](#1-daily-operations)
2. [Monitoring and Alerting](#2-monitoring-and-alerting)
3. [Scaling Operations](#3-scaling-operations)
4. [Backup and Recovery](#4-backup-and-recovery)
5. [Secret Management](#5-secret-management)
6. [User Management](#6-user-management)
7. [Certificate Management](#7-certificate-management)
8. [Cost Management](#8-cost-management)
9. [Security Operations](#9-security-operations)
10. [Maintenance Windows](#10-maintenance-windows)
11. [Incident Response](#11-incident-response)
12. [Runbook: Common Procedures](#12-runbook-common-procedures)

---

## 1. Daily Operations

### 1.1 Daily Health Check

Run this script every morning:

```bash
#!/bin/bash
# scripts/daily-health-check.sh

echo "=== THREE HORIZONS DAILY HEALTH CHECK ==="
echo "Date: $(date)"
echo ""

# 1. Cluster Health
echo "--- AKS Cluster Status ---"
kubectl get nodes -o wide
echo ""

# 2. Pod Health
echo "--- Problem Pods ---"
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded | grep -v "^NAMESPACE"
echo ""

# 3. ArgoCD Applications
echo "--- ArgoCD Applications ---"
kubectl get applications -n argocd -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status
echo ""

# 4. Resource Usage
echo "--- Node Resource Usage ---"
kubectl top nodes
echo ""

# 5. PVC Status
echo "--- Persistent Volume Claims ---"
kubectl get pvc -A | grep -v Bound
echo ""

# 6. Recent Events (Warnings)
echo "--- Recent Warning Events ---"
kubectl get events -A --field-selector type=Warning --sort-by='.lastTimestamp' | tail -20
echo ""

# 7. Cert Expiry Check
echo "--- Certificate Status ---"
kubectl get certificates -A 2>/dev/null || echo "cert-manager not installed"
echo ""

echo "=== HEALTH CHECK COMPLETE ==="
```

### 1.2 Key Metrics to Monitor

| Metric | Normal Range | Alert Threshold | Action |
|--------|--------------|-----------------|--------|
| Node CPU | < 70% | > 85% | Scale out nodes |
| Node Memory | < 80% | > 90% | Scale out nodes |
| Pod Restarts | 0-2 | > 5 | Investigate logs |
| API Server Latency | < 500ms | > 1s | Check control plane |
| Failed Pods | 0 | > 0 | Check events |
| PV Usage | < 80% | > 90% | Expand storage |

### 1.3 Daily Tasks Checklist

- [ ] Run health check script
- [ ] Review Grafana dashboards
- [ ] Check Slack/Teams for alerts
- [ ] Verify backup completion
- [ ] Review security alerts in Defender
- [ ] Check ArgoCD sync status
- [ ] Review cost anomalies

---

## 2. Monitoring and Alerting

### 2.1 Accessing Dashboards

```bash
# Grafana
kubectl port-forward svc/prometheus-grafana -n observability 3000:80
# URL: http://localhost:3000
# Get password: kubectl get secret prometheus-grafana -n observability -o jsonpath="{.data.admin-password}" | base64 -d

# Prometheus
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n observability 9090:9090
# URL: http://localhost:9090

# ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443
# URL: https://localhost:8080
```

### 2.2 Key Dashboards

| Dashboard | Purpose | Location |
|-----------|---------|----------|
| Platform Overview | Overall health | Grafana > Platform |
| Node Metrics | Node health | Grafana > Kubernetes > Nodes |
| Pod Metrics | Pod health | Grafana > Kubernetes > Pods |
| Cost Dashboard | Cost tracking | Grafana > Cost |
| Agent Metrics | AI agent stats | Grafana > Agents |

### 2.3 Alert Configuration

**File:** `prometheus/alerting-rules.yaml`

```yaml
groups:
  - name: platform-alerts
    rules:
      # High CPU Alert
      - alert: HighNodeCPU
        expr: (1 - avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m]))) > 0.85
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is above 85% for more than 10 minutes"

      # Memory Alert
      - alert: HighNodeMemory
        expr: (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) > 0.9
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"

      # Pod Crashloop
      - alert: PodCrashLooping
        expr: rate(kube_pod_container_status_restarts_total[15m]) * 60 * 15 > 3
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} is crash looping"

      # PVC Almost Full
      - alert: PVCAlmostFull
        expr: kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "PVC {{ $labels.persistentvolumeclaim }} is almost full"
```

### 2.4 Notification Channels

Configure in `argocd/notifications.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.teams: |
    recipientUrls:
      platform-team: $teams-webhook-url

  service.slack: |
    token: $slack-token

  trigger.on-sync-failed: |
    - send: [app-sync-failed]
      when: app.status.operationState.phase in ['Error', 'Failed']

  template.app-sync-failed: |
    teams:
      title: "Application Sync Failed"
      body: |
        Application: {{.app.metadata.name}}
        Status: {{.app.status.operationState.phase}}
        Message: {{.app.status.operationState.message}}
```

---

## 3. Scaling Operations

### 3.1 Manual Node Scaling

```bash
# Get current node count
az aks nodepool show \
  --resource-group rg-threehorizons-dev \
  --cluster-name aks-threehorizons-dev \
  --name user \
  --query "count"

# Scale up nodes
az aks nodepool scale \
  --resource-group rg-threehorizons-dev \
  --cluster-name aks-threehorizons-dev \
  --name user \
  --node-count 5

# Scale down nodes (careful!)
az aks nodepool scale \
  --resource-group rg-threehorizons-dev \
  --cluster-name aks-threehorizons-dev \
  --name user \
  --node-count 3
```

### 3.2 Configure Autoscaler

```bash
# Enable cluster autoscaler
az aks nodepool update \
  --resource-group rg-threehorizons-dev \
  --cluster-name aks-threehorizons-dev \
  --name user \
  --enable-cluster-autoscaler \
  --min-count 3 \
  --max-count 10
```

**Autoscaler Configuration via Terraform:**

```hcl
# terraform/modules/aks-cluster/main.tf

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = "Standard_D8s_v5"

  enable_auto_scaling = true
  min_count           = 3
  max_count           = 10

  node_labels = {
    "workload" = "general"
  }
}
```

### 3.3 Horizontal Pod Autoscaler (HPA)

```yaml
# Example HPA for application
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

### 3.4 Vertical Pod Autoscaler (VPA)

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: my-app-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
      - containerName: "*"
        minAllowed:
          cpu: 100m
          memory: 128Mi
        maxAllowed:
          cpu: 2
          memory: 4Gi
```

---

## 4. Backup and Recovery

### 4.1 Velero Setup

```bash
# Install Velero
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm repo update

# Create storage account for backups
az storage account create \
  --name stthreehorizonsbackup \
  --resource-group rg-threehorizons-dev \
  --location brazilsouth \
  --sku Standard_GRS

# Get storage key
AZURE_STORAGE_KEY=$(az storage account keys list \
  --account-name stthreehorizonsbackup \
  --resource-group rg-threehorizons-dev \
  --query "[0].value" -o tsv)

# Create blob container
az storage container create \
  --name velero \
  --account-name stthreehorizonsbackup \
  --account-key $AZURE_STORAGE_KEY

# Install Velero
velero install \
  --provider azure \
  --plugins velero/velero-plugin-for-microsoft-azure:v1.8.0 \
  --bucket velero \
  --secret-file ./credentials-velero \
  --backup-location-config resourceGroup=rg-threehorizons-dev,storageAccount=stthreehorizonsbackup \
  --snapshot-location-config apiTimeout=5m,resourceGroup=rg-threehorizons-dev
```

### 4.2 Backup Schedule

```bash
# Create daily backup schedule
velero schedule create daily-backup \
  --schedule="0 2 * * *" \
  --ttl 168h \
  --include-namespaces default,argocd,rhdh,observability

# Create weekly full backup
velero schedule create weekly-full \
  --schedule="0 3 * * 0" \
  --ttl 720h

# List schedules
velero schedule get
```

### 4.3 Manual Backup

```bash
# Backup specific namespace
velero backup create manual-backup-$(date +%Y%m%d) \
  --include-namespaces default,argocd \
  --wait

# Backup with volume snapshots
velero backup create manual-backup-with-volumes \
  --include-namespaces default \
  --snapshot-volumes=true \
  --wait

# Check backup status
velero backup describe manual-backup-$(date +%Y%m%d)
```

### 4.4 Restore Procedure

```bash
# List available backups
velero backup get

# Restore from backup
velero restore create --from-backup daily-backup-20251211020000

# Restore specific namespace
velero restore create --from-backup daily-backup-20251211020000 \
  --include-namespaces default

# Check restore status
velero restore describe <restore-name>
```

### 4.5 Database Backup

```bash
# PostgreSQL backup
az postgres flexible-server backup create \
  --resource-group rg-threehorizons-dev \
  --name psql-threehorizons-dev \
  --backup-name manual-backup-$(date +%Y%m%d)

# List backups
az postgres flexible-server backup list \
  --resource-group rg-threehorizons-dev \
  --name psql-threehorizons-dev \
  --output table
```

---

## 5. Secret Management

### 5.1 Adding New Secrets

```bash
# Add secret to Key Vault
az keyvault secret set \
  --vault-name kv-threehorizons-dev \
  --name "new-api-key" \
  --value "secret-value-here"

# Create ExternalSecret to sync
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: new-api-key
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: azure-key-vault
  target:
    name: new-api-key
    creationPolicy: Owner
  data:
    - secretKey: apiKey
      remoteRef:
        key: new-api-key
EOF

# Verify sync
kubectl get externalsecret new-api-key
kubectl get secret new-api-key
```

### 5.2 Rotating Secrets

```bash
# 1. Update in Key Vault
az keyvault secret set \
  --vault-name kv-threehorizons-dev \
  --name "db-password" \
  --value "new-password-here"

# 2. Force refresh of ExternalSecret
kubectl annotate externalsecret db-password \
  force-sync=$(date +%s) --overwrite

# 3. Restart pods to pick up new secret
kubectl rollout restart deployment/my-app -n default

# 4. Verify
kubectl get secret db-password -o jsonpath='{.data.password}' | base64 -d
```

### 5.3 Secret Audit

```bash
# List all secrets in Key Vault
az keyvault secret list \
  --vault-name kv-threehorizons-dev \
  --output table

# Check secret versions
az keyvault secret list-versions \
  --vault-name kv-threehorizons-dev \
  --name "db-password" \
  --output table

# Audit logs
az monitor activity-log list \
  --resource-group rg-threehorizons-dev \
  --resource-type Microsoft.KeyVault/vaults \
  --output table
```

---

## 6. User Management

### 6.1 AKS RBAC

```bash
# Get current cluster admin config
az aks get-credentials \
  --resource-group rg-threehorizons-dev \
  --name aks-threehorizons-dev \
  --admin

# Create ClusterRole for developers
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: developer
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["pods/log", "pods/exec"]
    verbs: ["get", "create"]
EOF

# Bind role to Azure AD group
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: developer-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: developer
subjects:
  - kind: Group
    name: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Azure AD Group Object ID
    apiGroup: rbac.authorization.k8s.io
EOF
```

### 6.2 ArgoCD Users

```yaml
# argocd/argocd-cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  accounts.developer: login
  accounts.readonly: login
```

```yaml
# argocd/argocd-rbac-cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.csv: |
    # Developers can sync apps in their namespaces
    p, role:developer, applications, sync, */*, allow
    p, role:developer, applications, get, */*, allow

    # Read-only role
    p, role:readonly, applications, get, */*, allow
    p, role:readonly, logs, get, */*, allow

    # Group bindings
    g, developers, role:developer
    g, viewers, role:readonly
```

### 6.3 Grafana Users

```bash
# Access Grafana admin
kubectl port-forward svc/prometheus-grafana -n observability 3000:80

# In Grafana UI:
# 1. Go to Configuration > Users
# 2. Add new user or configure LDAP/OAuth

# Or via API:
curl -X POST http://localhost:3000/api/admin/users \
  -H "Content-Type: application/json" \
  -u admin:$GRAFANA_PASSWORD \
  -d '{
    "name": "New Developer",
    "email": "dev@company.com",
    "login": "newdev",
    "password": "initial-password"
  }'
```

---

## 7. Certificate Management

### 7.1 Check Certificate Status

```bash
# List all certificates
kubectl get certificates -A

# Check certificate details
kubectl describe certificate tls-cert -n default

# Check cert-manager status
kubectl get challenges -A
kubectl get orders -A
```

### 7.2 Renew Certificate Manually

```bash
# Delete the secret to force renewal
kubectl delete secret tls-cert -n default

# cert-manager will automatically recreate it
kubectl get certificate tls-cert -n default -w
```

### 7.3 Create New Certificate

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: app-tls
  namespace: default
spec:
  secretName: app-tls-secret
  duration: 2160h  # 90 days
  renewBefore: 360h  # 15 days before expiry
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - app.example.com
    - www.app.example.com
```

---

## 8. Cost Management

### 8.1 View Current Costs

```bash
# Azure Cost Management
az consumption usage list \
  --subscription $SUBSCRIPTION_ID \
  --start-date $(date -d "-30 days" +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --output table

# Resource costs by tag
az consumption usage list \
  --subscription $SUBSCRIPTION_ID \
  --query "[?tags.Project=='ThreeHorizons']" \
  --output table
```

### 8.2 Budget Alerts

```bash
# Create budget
az consumption budget create \
  --budget-name threehorizons-monthly \
  --resource-group rg-threehorizons-dev \
  --amount 5000 \
  --time-grain Monthly \
  --start-date 2025-01-01 \
  --end-date 2025-12-31 \
  --category Cost
```

### 8.3 Cost Optimization Tasks

| Task | Frequency | Script |
|------|-----------|--------|
| Review idle resources | Weekly | `./scripts/cost-idle-resources.sh` |
| Right-size VMs | Monthly | `./scripts/cost-rightsizing.sh` |
| Reserved Instances | Quarterly | Azure Portal |
| Delete old snapshots | Weekly | `./scripts/cost-cleanup-snapshots.sh` |

### 8.4 Infracost Integration

```bash
# Run Infracost on Terraform
cd terraform
infracost breakdown --path . --format table

# Compare with previous
infracost diff --path . --compare-to infracost-base.json
```

---

## 9. Security Operations

### 9.1 Defender for Cloud Review

```bash
# Get security recommendations
az security assessment list \
  --subscription $SUBSCRIPTION_ID \
  --output table

# Get security alerts
az security alert list \
  --subscription $SUBSCRIPTION_ID \
  --output table
```

### 9.2 Vulnerability Scanning

```bash
# Scan container images in ACR
az acr task run \
  --registry acrthreehorizonsdev \
  --name vulnerability-scan

# List vulnerability results
az acr repository show-manifests \
  --name acrthreehorizonsdev \
  --repository my-app \
  --detail
```

### 9.3 Network Policy Audit

```bash
# List all network policies
kubectl get networkpolicies -A

# Verify policy is working
kubectl run test-pod --image=busybox --rm -it --restart=Never -- \
  wget -qO- --timeout=2 http://service.namespace.svc.cluster.local || echo "Blocked"
```

### 9.4 Gatekeeper Policy Violations

```bash
# Check violations
kubectl get constraints -o custom-columns=NAME:.metadata.name,VIOLATIONS:.status.totalViolations

# Get violation details
kubectl describe k8srequiredlabels require-labels
```

---

## 10. Maintenance Windows

### 10.1 AKS Upgrade

```bash
# Check available versions
az aks get-upgrades \
  --resource-group rg-threehorizons-dev \
  --name aks-threehorizons-dev \
  --output table

# Start upgrade (during maintenance window)
az aks upgrade \
  --resource-group rg-threehorizons-dev \
  --name aks-threehorizons-dev \
  --kubernetes-version 1.30.0 \
  --yes

# Monitor upgrade
watch kubectl get nodes
```

### 10.2 Node Pool Upgrade

```bash
# Upgrade specific node pool
az aks nodepool upgrade \
  --resource-group rg-threehorizons-dev \
  --cluster-name aks-threehorizons-dev \
  --name user \
  --kubernetes-version 1.30.0
```

### 10.3 Scheduled Maintenance

Configure in Terraform:

```hcl
resource "azurerm_kubernetes_cluster" "main" {
  # ... other config ...

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [2, 3, 4]
    }
  }

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    day_of_week = "Sunday"
    start_time  = "02:00"
    utc_offset  = "-03:00"
    duration    = 4
  }
}
```

---

## 11. Incident Response

### 11.1 Incident Severity Levels

| Level | Description | Response Time | Example |
|-------|-------------|---------------|---------|
| **SEV1** | Platform down | 15 min | All nodes NotReady |
| **SEV2** | Major degradation | 30 min | 50% pods failing |
| **SEV3** | Minor impact | 2 hours | Single app issues |
| **SEV4** | Low impact | 24 hours | Non-critical warnings |

### 11.2 SEV1 Response Checklist

```bash
# 1. Immediate triage
kubectl get nodes
kubectl get pods -A | grep -v Running

# 2. Check control plane
kubectl cluster-info
az aks show -g rg-threehorizons-dev -n aks-threehorizons-dev --query "powerState"

# 3. Check recent changes
kubectl get events -A --sort-by='.lastTimestamp' | tail -50
argocd app list

# 4. Rollback if needed
argocd app rollback <app-name> <previous-revision>

# 5. Scale up if resource constrained
az aks nodepool scale -g rg-threehorizons-dev --cluster-name aks-threehorizons-dev -n user --node-count 5
```

### 11.3 Post-Incident Review Template

```markdown
# Incident Review: [TITLE]

## Summary
- **Date:** YYYY-MM-DD
- **Duration:** X hours
- **Severity:** SEV-X
- **Impact:** Description of user impact

## Timeline
- HH:MM - Issue detected
- HH:MM - Investigation started
- HH:MM - Root cause identified
- HH:MM - Fix applied
- HH:MM - Service restored

## Root Cause
[Description of what caused the incident]

## Resolution
[Steps taken to resolve]

## Action Items
- [ ] Action 1 - Owner - Due Date
- [ ] Action 2 - Owner - Due Date

## Lessons Learned
[What we learned and how to prevent recurrence]
```

---

## 12. Runbook: Common Procedures

### 12.1 Deploy New Application

```bash
# 1. Create namespace
kubectl create namespace my-new-app

# 2. Create ArgoCD Application
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-new-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/my-new-app.git
    targetRevision: main
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: my-new-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

# 3. Verify deployment
argocd app get my-new-app
kubectl get pods -n my-new-app
```

### 12.2 Drain Node for Maintenance

```bash
# 1. Cordon node (prevent new pods)
kubectl cordon aks-user-12345678-vmss000001

# 2. Drain pods
kubectl drain aks-user-12345678-vmss000001 \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --force

# 3. Perform maintenance...

# 4. Uncordon node
kubectl uncordon aks-user-12345678-vmss000001
```

### 12.3 Force Delete Stuck Namespace

```bash
# Get namespace in Terminating state
kubectl get namespace stuck-namespace -o json > ns.json

# Remove finalizers
jq '.spec.finalizers = []' ns.json > ns-clean.json

# Apply via API
kubectl proxy &
curl -k -H "Content-Type: application/json" \
  -X PUT --data-binary @ns-clean.json \
  http://127.0.0.1:8001/api/v1/namespaces/stuck-namespace/finalize
```

### 12.4 Restart All Pods in Namespace

```bash
# Restart all deployments
kubectl rollout restart deployment -n my-namespace

# Restart all statefulsets
kubectl rollout restart statefulset -n my-namespace

# Restart all daemonsets
kubectl rollout restart daemonset -n my-namespace
```

### 12.5 Emergency Rollback

```bash
# Via ArgoCD
argocd app history my-app
argocd app rollback my-app <revision>

# Via kubectl
kubectl rollout history deployment/my-app -n my-namespace
kubectl rollout undo deployment/my-app -n my-namespace --to-revision=2
```

### 12.6 Export All Resources from Namespace

```bash
# Export all resources
kubectl get all,configmap,secret,pvc,ingress,networkpolicy -n my-namespace -o yaml > namespace-backup.yaml
```

---

## Quick Reference

### Essential Commands

```bash
# Cluster info
kubectl cluster-info
kubectl get nodes -o wide

# Pod troubleshooting
kubectl logs <pod> -n <namespace> -f
kubectl exec -it <pod> -n <namespace> -- /bin/sh
kubectl describe pod <pod> -n <namespace>

# Resource usage
kubectl top nodes
kubectl top pods -A

# Events
kubectl get events -A --sort-by='.lastTimestamp'

# ArgoCD
argocd app list
argocd app sync <app>
argocd app diff <app>
```

### Important Paths

| Path | Description |
|------|-------------|
| `terraform/` | Infrastructure as Code |
| `argocd/apps/` | Application definitions |
| `prometheus/alerting-rules.yaml` | Alert configurations |
| `grafana/dashboards/` | Dashboard JSON files |
| `scripts/` | Automation scripts |

---

**Document Version:** 1.0.0
**Last Updated:** December 2025
**Maintainer:** Platform Engineering Team
