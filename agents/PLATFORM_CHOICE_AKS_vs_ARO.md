# Platform Choice: ARO vs AKS

## Overview

The Three Horizons Accelerator supports **two enterprise Kubernetes platforms**:

1. **Azure Kubernetes Service (AKS)** - Azure-native managed Kubernetes
2. **Azure Red Hat OpenShift (ARO)** - Red Hat's enterprise Kubernetes platform

**This is a mutually exclusive choice made at deployment start.**

---

## Decision Criteria

| Factor | AKS | ARO |
|--------|-----|-----|
| **Best For** | Azure-native workloads | Red Hat ecosystem shops |
| **Management** | Simpler, Azure-native | Enterprise support, Red Hat |
| **Cost** | Lower (managed service) | Higher (includes RHEL CoreOS + support) |
| **Support** | Microsoft Azure support | Red Hat enterprise support |
| **Operators** | Helm-based | OpenShift Operators + Helm |
| **GitOps** | ArgoCD (manual install) | OpenShift GitOps (built-in) |
| **Developer Portal** | RHDH (manual install) | OpenShift Console + RHDH |
| **Security** | Azure Defender | OpenShift + Azure Defender |
| **Compliance** | Azure compliance | Red Hat + Azure compliance |
| **Container Registry** | ACR | ACR or OpenShift Registry |

---

## When to Choose AKS

✅ **Choose AKS if you:**
- Are primarily an Azure shop
- Want native Azure integrations
- Prefer simpler management
- Need lower costs
- Don't require Red Hat support
- Have small-medium teams (< 50 devs)

**Agent:** Use `infrastructure-agent` (deploys AKS)

---

## When to Choose ARO

✅ **Choose ARO if you:**
- Are a Red Hat ecosystem organization
- Require Red Hat enterprise support
- Need OpenShift Operators
- Want built-in GitOps (OpenShift GitOps)
- Have compliance requirements for Red Hat
- Have large teams (50+ devs) needing enterprise features
- Already use Red Hat products (RHEL, Ansible, etc.)

**Agent:** Use `aro-platform-agent` (deploys ARO)

---

## Cost Comparison (Brazil South)

### Small Deployment (< 10 devs)

**AKS:**
- 3 nodes (D4s_v5): ~$300/month
- **Total: ~$300/month**

**ARO:**
- 3 worker nodes + 3 control plane nodes: ~$800/month
- **Total: ~$800/month**

### Medium Deployment (10-50 devs)

**AKS:**
- 5 nodes (D8s_v5): ~$1,000/month
- **Total: ~$1,000/month**

**ARO:**
- 5 worker nodes + 3 control plane nodes: ~$1,500/month
- **Total: ~$1,500/month**

### Large Deployment (50-200 devs)

**AKS:**
- 10 nodes (D16s_v5): ~$3,000/month
- **Total: ~$3,000/month**

**ARO:**
- 10 worker nodes + 3 control plane nodes: ~$4,500/month
- **Total: ~$4,500/month**

---

## Feature Comparison

| Feature | AKS | ARO | Notes |
|---------|-----|-----|-------|
| Kubernetes API | ✅ | ✅ | Both fully compliant |
| Azure Integration | ✅ Native | ✅ Supported | AKS has deeper integration |
| GitOps (ArgoCD) | ✅ Manual install | ✅ Built-in | ARO includes OpenShift GitOps |
| Operators | ⚠️ Via Helm | ✅ Native | ARO has Operator Hub |
| Web Console | Basic | ✅ Full | ARO has comprehensive console |
| RBAC | ✅ | ✅ | Both support K8s RBAC |
| Monitoring | Manual (Prometheus) | ✅ Built-in | ARO includes monitoring |
| Logging | Manual (Loki) | ✅ Built-in | ARO includes logging |
| Service Mesh | Manual (Istio) | ✅ Built-in | ARO includes OpenShift Service Mesh |
| Serverless | Manual (Knative) | ✅ Built-in | ARO includes OpenShift Serverless |

---

## Deployment Process

### Deploying AKS

1. Create GitHub Issue: "Deploy Infrastructure"
2. Add labels: `agent:infrastructure`, `approved`
3. Configure in issue:
   ```yaml
   platform: aks
   sizing: medium
   region: brazilsouth
   ```
4. Workflow runs: `infrastructure-deploy.yml`
5. Duration: ~25-35 minutes

### Deploying ARO

1. Create GitHub Issue: "Deploy ARO Platform"
2. Add labels: `agent:aro-platform`, `approved`
3. Configure in issue:
   ```yaml
   platform: aro
   sizing: medium
   region: brazilsouth
   ```
4. Workflow runs: `aro-platform-deploy.yml`
5. Duration: ~30-45 minutes

---

## Migration Between Platforms

⚠️ **Warning:** Migrating between AKS and ARO requires careful planning.

**AKS → ARO:**
- Workloads can be migrated using Velero backup/restore
- Reconfigure GitOps for OpenShift GitOps
- Update container images (may need RHEL UBI base)

**ARO → AKS:**
- Export workloads using Velero
- Rebuild infrastructure with AKS
- Redeploy GitOps (ArgoCD)

**Recommendation:** Choose the right platform from the start.

---

## Conclusion

**Both platforms are fully supported** by the Three Horizons Accelerator:

- **AKS:** Great for Azure-native teams, simpler, lower cost
- **ARO:** Great for Red Hat shops, enterprise features, comprehensive support

**Choose based on your organization's ecosystem and requirements.**

---

**Last Updated:** February 2, 2026
