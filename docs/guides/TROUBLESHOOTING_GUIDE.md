# Three Horizons Accelerator - Troubleshooting Guide

> **Version:** 4.0.0
> **Last Updated:** December 2025

---

## Table of Contents

1. [Quick Diagnostics](#1-quick-diagnostics)
2. [Terraform Issues](#2-terraform-issues)
3. [AKS Cluster Issues](#3-aks-cluster-issues)
4. [ArgoCD Issues](#4-argocd-issues)
5. [Networking Issues](#5-networking-issues)
6. [External Secrets Issues](#6-external-secrets-issues)
7. [Observability Issues](#7-observability-issues)
8. [AI Foundry Issues](#8-ai-foundry-issues)
9. [Authentication Issues](#9-authentication-issues)
10. [Performance Issues](#10-performance-issues)
11. [Common Error Messages](#11-common-error-messages)
12. [Support Escalation](#12-support-escalation)

---

## 1. Quick Diagnostics

### Universal Diagnostic Script

```bash
#!/bin/bash
# scripts/diagnose.sh - Run this first for any issue

echo "=== THREE HORIZONS DIAGNOSTIC REPORT ==="
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

# Cluster connectivity
echo "--- Cluster Connectivity ---"
kubectl cluster-info 2>&1 || echo "ERROR: Cannot connect to cluster"
echo ""

# Node status
echo "--- Node Status ---"
kubectl get nodes -o wide 2>&1
echo ""

# Pod issues
echo "--- Non-Running Pods ---"
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded 2>&1
echo ""

# Recent events
echo "--- Recent Warning Events (last 10) ---"
kubectl get events -A --field-selector type=Warning --sort-by='.lastTimestamp' 2>&1 | tail -10
echo ""

# Resource pressure
echo "--- Resource Usage ---"
kubectl top nodes 2>&1 || echo "Metrics server not available"
echo ""

# ArgoCD status
echo "--- ArgoCD Applications ---"
kubectl get applications -n argocd 2>&1 || echo "ArgoCD not installed"
echo ""

# External Secrets
echo "--- External Secrets Status ---"
kubectl get externalsecrets -A 2>&1 | head -10 || echo "ESO not installed"
echo ""

echo "=== END DIAGNOSTIC REPORT ==="
```

### Decision Tree

```
Issue detected
    │
    ├─► Cannot connect to cluster?
    │       └─► See Section 3.1 (Cluster Access)
    │
    ├─► Pods not starting?
    │       └─► See Section 3.3 (Pod Issues)
    │
    ├─► Apps not syncing?
    │       └─► See Section 4 (ArgoCD)
    │
    ├─► Secrets not syncing?
    │       └─► See Section 6 (External Secrets)
    │
    ├─► Network connectivity?
    │       └─► See Section 5 (Networking)
    │
    └─► Performance problems?
            └─► See Section 10 (Performance)
```

---

## 2. Terraform Issues

### 2.1 Terraform Init Fails

**Symptom:**
```
Error: Failed to get existing workspaces: storage: service returned error
```

**Causes & Solutions:**

| Cause | Solution |
|-------|----------|
| Storage account not accessible | Check network/firewall rules |
| Expired credentials | Run `az login` again |
| Missing permissions | Verify Storage Blob Data Contributor role |

**Fix:**
```bash
# Clear local cache
rm -rf .terraform .terraform.lock.hcl

# Re-authenticate
az login
az account set --subscription $SUBSCRIPTION_ID

# Reinitialize
terraform init -reconfigure
```

### 2.2 Provider Authentication Failed

**Symptom:**
```
Error: Error building AzureRM Client: obtain subscription() from Azure CLI
```

**Fix:**
```bash
# Check current authentication
az account show

# If using service principal
export ARM_CLIENT_ID="xxx"
export ARM_CLIENT_SECRET="xxx"
export ARM_SUBSCRIPTION_ID="xxx"
export ARM_TENANT_ID="xxx"

# Verify
terraform plan
```

### 2.3 State Lock Error

**Symptom:**
```
Error: Error acquiring the state lock
```

**Fix:**
```bash
# Force unlock (use with caution!)
terraform force-unlock <LOCK_ID>

# If lock persists, check Azure Storage
az storage blob lease break \
  --blob-name terraform.tfstate \
  --container-name tfstate \
  --account-name $STORAGE_ACCOUNT
```

### 2.4 Resource Already Exists

**Symptom:**
```
Error: A resource with the ID "..." already exists
```

**Solutions:**
```bash
# Option 1: Import existing resource
terraform import azurerm_resource_group.main /subscriptions/.../resourceGroups/rg-name

# Option 2: Remove from state (if orphaned)
terraform state rm azurerm_resource_group.main

# Option 3: Delete in Azure and re-apply
az group delete --name rg-name --yes --no-wait
terraform apply
```

### 2.5 Quota Exceeded

**Symptom:**
```
Error: creating/updating ... QuotaExceeded
```

**Fix:**
```bash
# Check current usage
az vm list-usage --location brazilsouth --output table

# Request quota increase via Azure Portal
# Or use smaller VM sizes temporarily
```

---

## 3. AKS Cluster Issues

### 3.1 Cannot Connect to Cluster

**Symptom:**
```
Unable to connect to the server: dial tcp: lookup ... no such host
```

**Diagnostic:**
```bash
# Check kubeconfig
kubectl config view
kubectl config current-context

# Verify AKS is running
az aks show -g $RG -n $CLUSTER --query "powerState"
```

**Solutions:**

| Cause | Solution |
|-------|----------|
| Wrong context | `kubectl config use-context <correct-context>` |
| Expired credentials | `az aks get-credentials -g $RG -n $CLUSTER --overwrite-existing` |
| Cluster stopped | `az aks start -g $RG -n $CLUSTER` |
| Private cluster + no access | Connect via bastion or authorized IP |

### 3.2 Nodes Not Ready

**Symptom:**
```
NAME                 STATUS     ROLES   AGE
aks-node-xxxxx       NotReady   agent   10d
```

**Diagnostic:**
```bash
# Get node details
kubectl describe node aks-node-xxxxx

# Check conditions
kubectl get node aks-node-xxxxx -o jsonpath='{.status.conditions[*].message}'
```

**Common Causes:**

| Condition | Cause | Solution |
|-----------|-------|----------|
| NetworkUnavailable | CNI issue | Restart kubelet, check NSG |
| MemoryPressure | OOM | Scale up node size or add nodes |
| DiskPressure | Disk full | Clean up images, expand disk |
| PIDPressure | Too many processes | Investigate workloads |

**Fix network issue:**
```bash
# Reimage the node
az aks nodepool update \
  --resource-group $RG \
  --cluster-name $CLUSTER \
  --name system \
  --max-surge 1

# Or cordon and drain
kubectl cordon $NODE
kubectl drain $NODE --ignore-daemonsets --delete-emptydir-data
az vmss reimage --instance-id X --name $VMSS --resource-group $MC_RG
kubectl uncordon $NODE
```

### 3.3 Pods Stuck in Pending

**Symptom:**
```
NAME           READY   STATUS    RESTARTS   AGE
my-pod         0/1     Pending   0          10m
```

**Diagnostic:**
```bash
kubectl describe pod my-pod -n my-namespace
```

**Solutions by Cause:**

| Event Message | Cause | Solution |
|--------------|-------|----------|
| `Insufficient cpu` | Not enough CPU | Scale nodes or reduce requests |
| `Insufficient memory` | Not enough memory | Scale nodes or reduce requests |
| `no nodes available to schedule` | Taints/tolerations | Add tolerations or untaint nodes |
| `PersistentVolumeClaim not found` | PVC missing | Create PVC first |
| `0/3 nodes are available: pod has unbound immediate PersistentVolumeClaims` | Storage class issue | Check storage class exists |

**Quick fixes:**
```bash
# Scale up nodes
az aks nodepool scale -g $RG --cluster-name $CLUSTER -n user --node-count 5

# Check node taints
kubectl describe nodes | grep Taints

# Remove taint if needed
kubectl taint nodes $NODE key=value:NoSchedule-
```

### 3.4 Pods Stuck in ImagePullBackOff

**Symptom:**
```
NAME           READY   STATUS             RESTARTS   AGE
my-pod         0/1     ImagePullBackOff   0          10m
```

**Diagnostic:**
```bash
kubectl describe pod my-pod | grep -A 5 "Events:"
```

**Solutions:**

| Cause | Solution |
|-------|----------|
| Image doesn't exist | Check image name/tag, push to ACR |
| ACR authentication | Attach ACR to AKS or create image pull secret |
| Private registry | Create imagePullSecrets |
| Network issue | Check NSG, private endpoint |

**Fix ACR access:**
```bash
# Attach ACR to AKS
az aks update -g $RG -n $CLUSTER --attach-acr $ACR_NAME

# Or create pull secret manually
kubectl create secret docker-registry acr-secret \
  --docker-server=$ACR_LOGIN_SERVER \
  --docker-username=$SP_ID \
  --docker-password=$SP_PASSWORD \
  -n my-namespace
```

### 3.5 CrashLoopBackOff

**Symptom:**
```
NAME           READY   STATUS             RESTARTS   AGE
my-pod         0/1     CrashLoopBackOff   5          10m
```

**Diagnostic:**
```bash
# Check logs
kubectl logs my-pod -n my-namespace --previous

# Check events
kubectl describe pod my-pod -n my-namespace

# Get exit code
kubectl get pod my-pod -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}'
```

**Common Exit Codes:**

| Code | Meaning | Common Cause |
|------|---------|--------------|
| 0 | Success | App exited normally (check liveness probe) |
| 1 | Error | Application error, check logs |
| 137 | SIGKILL | OOMKilled, increase memory |
| 143 | SIGTERM | Graceful shutdown timeout |

---

## 4. ArgoCD Issues

### 4.1 Application Out of Sync

**Symptom:**
```
NAME     SYNC STATUS   HEALTH STATUS
my-app   OutOfSync     Healthy
```

**Diagnostic:**
```bash
# Check diff
argocd app diff my-app

# Check events
argocd app get my-app --show-operation
```

**Solutions:**

| Cause | Solution |
|-------|----------|
| Manual changes in cluster | Sync with `--prune` |
| Git webhook not firing | Manual sync or check webhook |
| Invalid manifest | Fix YAML in Git |
| Resource conflict | Check for duplicate resources |

**Fix:**
```bash
# Force sync
argocd app sync my-app --force

# Sync with prune (removes extra resources)
argocd app sync my-app --prune

# Hard refresh
argocd app get my-app --hard-refresh
```

### 4.2 Application Stuck in Progressing

**Symptom:** App stays in "Progressing" health status.

**Diagnostic:**
```bash
# Check what's not ready
kubectl get all -n my-app-namespace
kubectl get pods -n my-app-namespace -o wide

# Check deployment rollout
kubectl rollout status deployment/my-app -n my-app-namespace
```

**Common Causes:**
- Deployment stuck (see Pod issues)
- Health check misconfigured
- External dependency not available

### 4.3 Cannot Login to ArgoCD

**Symptom:** 403 Forbidden or authentication failed.

**Solutions:**
```bash
# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Reset admin password
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {"admin.password": "'$(htpasswd -bnBC 10 "" newpassword | tr -d ':\n')'"}}'

# Restart ArgoCD server
kubectl rollout restart deployment argocd-server -n argocd
```

### 4.4 Sync Hook Failed

**Symptom:**
```
Error: hook failed: Job ... failed
```

**Diagnostic:**
```bash
# Find failed job
kubectl get jobs -n my-namespace

# Check job logs
kubectl logs job/pre-sync-job -n my-namespace
```

**Fix:**
```bash
# Delete failed job to retry
kubectl delete job pre-sync-job -n my-namespace

# Retry sync
argocd app sync my-app
```

---

## 5. Networking Issues

### 5.1 Pod Cannot Reach External Service

**Symptom:** Connection timeout to external APIs.

**Diagnostic:**
```bash
# Test from pod
kubectl run debug --rm -it --image=busybox -- wget -qO- http://example.com

# Check DNS resolution
kubectl run debug --rm -it --image=busybox -- nslookup example.com

# Check NSG rules
az network nsg rule list --nsg-name nsg-aks -g $RG -o table
```

**Solutions:**

| Cause | Solution |
|-------|----------|
| DNS not working | Check CoreDNS pods, restart if needed |
| NSG blocking | Add outbound rule for destination |
| No egress path | Check NAT gateway or load balancer |
| Network policy blocking | Check network policies in namespace |

**Fix DNS:**
```bash
# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Restart CoreDNS
kubectl rollout restart deployment coredns -n kube-system
```

### 5.2 Service Not Accessible

**Symptom:** Cannot reach service from other pods.

**Diagnostic:**
```bash
# Check service exists
kubectl get svc -n my-namespace

# Check endpoints
kubectl get endpoints my-service -n my-namespace

# Test connectivity
kubectl run debug --rm -it --image=busybox -- wget -qO- http://my-service.my-namespace.svc.cluster.local
```

**Solutions:**

| Issue | Solution |
|-------|----------|
| No endpoints | Check pod labels match service selector |
| Wrong port | Verify service port matches container port |
| Network policy | Check if ingress is allowed |

### 5.3 Private Endpoint Not Working

**Symptom:** Cannot reach Azure service via private endpoint.

**Diagnostic:**
```bash
# Check private endpoint
az network private-endpoint show -g $RG -n pe-keyvault -o table

# Check DNS resolution
kubectl run debug --rm -it --image=busybox -- nslookup kv-threehorizons-dev.vault.azure.net
```

**Expected:** Should resolve to private IP (10.x.x.x), not public IP.

**Fix:**
```bash
# Check private DNS zone link
az network private-dns link vnet list \
  --resource-group $RG \
  --zone-name privatelink.vaultcore.azure.net

# Create link if missing
az network private-dns link vnet create \
  --resource-group $RG \
  --zone-name privatelink.vaultcore.azure.net \
  --name vnet-link \
  --virtual-network $VNET_NAME \
  --registration-enabled false
```

---

## 6. External Secrets Issues

### 6.1 ExternalSecret Not Syncing

**Symptom:**
```
kubectl get externalsecret my-secret -n my-namespace
NAME        STORE           REFRESH    STATUS
my-secret   azure-key-vault 1h         SecretSyncedError
```

**Diagnostic:**
```bash
# Check ExternalSecret status
kubectl describe externalsecret my-secret -n my-namespace

# Check ESO controller logs
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets
```

**Common Errors:**

| Error | Cause | Solution |
|-------|-------|----------|
| `could not get secret` | Wrong secret name | Verify secret exists in Key Vault |
| `authentication failed` | Workload identity issue | Check service account annotation |
| `forbidden` | Missing RBAC | Add Key Vault access policy |

### 6.2 Workload Identity Not Working

**Diagnostic:**
```bash
# Check service account annotation
kubectl get sa external-secrets -n external-secrets -o yaml | grep azure.workload.identity

# Check federated credential
az identity federated-credential list \
  --identity-name id-threehorizons-dev-workload \
  --resource-group $RG
```

**Fix:**
```bash
# Ensure service account has annotation
kubectl annotate sa external-secrets \
  azure.workload.identity/client-id=$CLIENT_ID \
  -n external-secrets --overwrite

# Restart ESO to pick up changes
kubectl rollout restart deployment external-secrets -n external-secrets
```

### 6.3 Secret Not Updating

**Symptom:** Secret in cluster has old value after updating in Key Vault.

**Solutions:**
```bash
# Check refresh interval in ExternalSecret
kubectl get externalsecret my-secret -o jsonpath='{.spec.refreshInterval}'

# Force refresh
kubectl annotate externalsecret my-secret \
  force-sync=$(date +%s) \
  --overwrite -n my-namespace

# Or delete and recreate the K8s secret
kubectl delete secret my-secret -n my-namespace
```

---

## 7. Observability Issues

### 7.1 Prometheus Not Scraping Targets

**Symptom:** Missing metrics in Grafana.

**Diagnostic:**
```bash
# Access Prometheus
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n observability 9090:9090

# Check targets at http://localhost:9090/targets
```

**Common Issues:**

| Status | Cause | Solution |
|--------|-------|----------|
| DOWN | Network policy blocking | Allow scraping in network policy |
| unhealthy | Wrong port/path | Check ServiceMonitor configuration |
| missing | No ServiceMonitor | Create ServiceMonitor for your app |

**Create ServiceMonitor:**
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-app-monitor
  namespace: observability
spec:
  selector:
    matchLabels:
      app: my-app
  namespaceSelector:
    matchNames:
      - my-namespace
  endpoints:
    - port: metrics
      path: /metrics
      interval: 30s
```

### 7.2 Grafana Dashboard Not Loading

**Symptom:** Dashboard shows "No Data".

**Diagnostic:**
```bash
# Check Grafana data source
kubectl port-forward svc/prometheus-grafana -n observability 3000:80
# Go to Configuration > Data Sources > Test
```

**Solutions:**

| Issue | Solution |
|-------|----------|
| Wrong data source URL | Use `http://prometheus-kube-prometheus-prometheus.observability:9090` |
| Query returns empty | Check query in Prometheus first |
| Time range issue | Adjust time range in Grafana |

### 7.3 Alerts Not Firing

**Diagnostic:**
```bash
# Check alert rules
kubectl get prometheusrules -n observability

# Check AlertManager
kubectl port-forward svc/prometheus-kube-prometheus-alertmanager -n observability 9093:9093
```

---

## 8. AI Foundry Issues

### 8.1 API Request Failed

**Symptom:**
```
Error: 429 Too Many Requests - Rate limit exceeded
```

**Solutions:**
```bash
# Check current usage
az cognitiveservices account show \
  --name $AI_ACCOUNT \
  --resource-group $RG \
  --query "properties.quotaLimit"

# Increase quota
az cognitiveservices account deployment update \
  --name $AI_ACCOUNT \
  --resource-group $RG \
  --deployment-name gpt-4o \
  --capacity 20
```

### 8.2 Model Not Available

**Symptom:**
```
Error: Model 'gpt-4o' is not available in region 'brazilsouth'
```

**Solution:** Deploy to East US 2 for full model availability.

```hcl
# terraform/modules/ai-foundry/variables.tf
variable "location" {
  default = "eastus2"  # Use East US 2 for full model catalog
}
```

### 8.3 Private Endpoint Connection Failed

**Diagnostic:**
```bash
# Test from AKS pod
kubectl run debug --rm -it --image=mcr.microsoft.com/azure-cli -- \
  az cognitiveservices account show --name $AI_ACCOUNT -g $RG

# Check private endpoint
az network private-endpoint show -n pe-ai -g $RG
```

---

## 9. Authentication Issues

### 9.1 Azure CLI Session Expired

**Symptom:**
```
AADSTS700082: The refresh token has expired
```

**Fix:**
```bash
az logout
az login
az account set --subscription $SUBSCRIPTION_ID
```

### 9.2 GitHub Token Expired

**Symptom:** GitHub Actions fail with 401.

**Fix:**
```bash
# Regenerate token
gh auth login

# Update repository secret
gh secret set GITHUB_TOKEN < token.txt
```

### 9.3 Service Principal Expired

**Symptom:**
```
AADSTS7000215: Invalid client secret provided
```

**Fix:**
```bash
# Create new secret
az ad sp credential reset --name $SP_NAME

# Update GitHub secrets
gh secret set ARM_CLIENT_SECRET --body "new-secret"
```

---

## 10. Performance Issues

### 10.1 High API Server Latency

**Diagnostic:**
```bash
# Check API server metrics
kubectl get --raw /metrics | grep apiserver_request_duration

# Check etcd
kubectl -n kube-system logs etcd-master | tail -50
```

**Solutions:**
- Reduce watch connections
- Upgrade to larger control plane (Premium AKS)
- Review custom controllers making excessive API calls

### 10.2 Slow Pod Startup

**Diagnostic:**
```bash
# Check image pull time
kubectl describe pod my-pod | grep -A 10 Events

# Check init containers
kubectl logs my-pod -c init-container
```

**Solutions:**

| Cause | Solution |
|-------|----------|
| Large image | Use smaller base images, multi-stage builds |
| Slow image pull | Use ACR in same region, enable image caching |
| Init container slow | Optimize init logic |
| Slow readiness probe | Adjust `initialDelaySeconds` |

### 10.3 Memory/CPU Throttling

**Diagnostic:**
```bash
# Check resource usage
kubectl top pods -n my-namespace

# Check throttling
kubectl describe pod my-pod | grep -i throttl
```

**Fix:**
```yaml
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "2000m"      # Increase limit
    memory: "2Gi"     # Increase limit
```

---

## 11. Common Error Messages

### Error Reference Table

| Error | Likely Cause | Quick Fix |
|-------|--------------|-----------|
| `connection refused` | Service not running | Check pod status, port |
| `no such host` | DNS issue | Check CoreDNS, service name |
| `timeout` | Network policy, NSG | Check network policies |
| `403 Forbidden` | RBAC, authentication | Check roles, tokens |
| `ImagePullBackOff` | Registry access | Check ACR attachment |
| `CrashLoopBackOff` | App error | Check logs |
| `OOMKilled` | Memory exhausted | Increase memory limit |
| `Evicted` | Node pressure | Scale nodes, check disk |
| `FailedScheduling` | Resources, taints | Scale up or add tolerations |
| `InvalidImageName` | Wrong image reference | Check image name syntax |

---

## 12. Support Escalation

### When to Escalate

- SEV1 incidents lasting > 30 minutes
- Data loss or security breach
- Repeated failures with no clear cause
- Issues affecting multiple customers

### Information to Collect

```bash
# Generate support bundle
./scripts/support-bundle.sh > support-bundle-$(date +%Y%m%d).txt

# Include:
# 1. Diagnostic output (Section 1)
# 2. Recent events
# 3. Relevant pod logs
# 4. Terraform state (sanitized)
# 5. ArgoCD app status
```

### Support Channels

| Channel | Use Case | SLA |
|---------|----------|-----|
| GitHub Issues | Bug reports, features | Best effort |
| Slack #platform-help | Quick questions | Business hours |
| PagerDuty | SEV1/SEV2 incidents | 15 min response |
| Azure Support | Azure-specific issues | Per support plan |

---

## Appendix: Diagnostic Commands Cheatsheet

```bash
# Cluster
kubectl cluster-info
kubectl get nodes -o wide
kubectl top nodes

# Pods
kubectl get pods -A
kubectl describe pod <pod>
kubectl logs <pod> -f
kubectl exec -it <pod> -- /bin/sh

# Events
kubectl get events -A --sort-by='.lastTimestamp'

# Network
kubectl get svc,ep,netpol -A
kubectl run debug --rm -it --image=busybox -- sh

# Storage
kubectl get pv,pvc -A
kubectl describe pv <pv>

# ArgoCD
argocd app list
argocd app get <app>
argocd app sync <app>

# Azure
az aks show -g $RG -n $CLUSTER
az network private-endpoint list -g $RG
az keyvault secret list --vault-name $KV
```

---

**Document Version:** 1.0.0
**Last Updated:** December 2025
**Maintainer:** Platform Engineering Team
