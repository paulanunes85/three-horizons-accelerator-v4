---
description: 'ArgoCD GitOps standards, application patterns, sync policies, and repository configuration for Three Horizons Accelerator deployments'
applyTo: '**/argocd/**/*.yaml,**/argocd/**/*.yml'
---

# ArgoCD GitOps Standards

## Directory Structure

```
argocd/
├── README.md
├── app-of-apps/
│   └── root-application.yaml
├── apps/
│   ├── external-secrets.yaml
│   ├── gatekeeper.yaml
│   └── observability.yaml
├── secrets/
│   └── cluster-secret-store.yaml
├── repo-credentials.yaml
└── sync-policies.yaml
```

## Application Template

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-name
  namespace: argocd
  labels:
    app.kubernetes.io/name: app-name
    app.kubernetes.io/part-of: three-horizons
    horizon: h1|h2|h3
  annotations:
    notifications.argoproj.io/subscribe.on-sync-succeeded.slack: platform-alerts
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/org/repo.git
    targetRevision: HEAD
    path: deploy/kubernetes/app-name
    # For Kustomize
    kustomize:
      namePrefix: dev-
    # For Helm
    helm:
      valueFiles:
        - values.yaml
        - values-dev.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: app-namespace
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - PruneLast=true
      - ServerSideApply=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

## App-of-Apps Pattern

```yaml
# argocd/app-of-apps/root-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: apps
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/org/repo.git
    targetRevision: HEAD
    path: argocd/apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## ApplicationSet Pattern

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: cluster-apps
  namespace: argocd
spec:
  generators:
    - list:
        elements:
          - cluster: dev
            url: https://dev-cluster.example.com
          - cluster: staging
            url: https://staging-cluster.example.com
          - cluster: prod
            url: https://prod-cluster.example.com
  template:
    metadata:
      name: '{{cluster}}-app'
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: https://github.com/org/repo.git
        targetRevision: HEAD
        path: 'deploy/overlays/{{cluster}}'
      destination:
        server: '{{url}}'
        namespace: app-namespace
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

## Sync Policies

### Automated Sync (Recommended)

```yaml
syncPolicy:
  automated:
    prune: true       # Remove resources not in Git
    selfHeal: true    # Revert manual changes
  syncOptions:
    - CreateNamespace=true
    - PruneLast=true
    - ServerSideApply=true
```

### Manual Sync (Production)

```yaml
syncPolicy:
  syncOptions:
    - CreateNamespace=true
    - PruneLast=true
  # No automated section = manual sync required
```

## Retry Configuration

```yaml
retry:
  limit: 5
  backoff:
    duration: 5s
    factor: 2
    maxDuration: 3m
```

## Health Checks

### Custom Health Check

```yaml
# In ArgoCD ConfigMap
resource.customizations.health.networking.k8s.io_Ingress: |
  hs = {}
  if obj.status ~= nil then
    if obj.status.loadBalancer ~= nil then
      hs.status = "Healthy"
      hs.message = "Ingress has load balancer"
      return hs
    end
  end
  hs.status = "Progressing"
  hs.message = "Waiting for load balancer"
  return hs
```

## Repository Credentials

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: repo-creds
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repo-creds
stringData:
  type: git
  url: https://github.com/org
  password: ${GITHUB_TOKEN}
  username: git
```

## Project Configuration

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: production
  namespace: argocd
spec:
  description: Production workloads
  sourceRepos:
    - 'https://github.com/org/*'
  destinations:
    - namespace: '*'
      server: https://kubernetes.default.svc
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
  namespaceResourceBlacklist:
    - group: ''
      kind: ResourceQuota
    - group: ''
      kind: LimitRange
```

## Labeling Standards

Required labels for all ArgoCD Applications:

```yaml
labels:
  app.kubernetes.io/name: app-name
  app.kubernetes.io/part-of: three-horizons
  horizon: h1|h2|h3
  environment: dev|staging|prod
```

## Notifications (Optional)

```yaml
annotations:
  notifications.argoproj.io/subscribe.on-sync-succeeded.slack: platform-alerts
  notifications.argoproj.io/subscribe.on-sync-failed.slack: platform-alerts
  notifications.argoproj.io/subscribe.on-health-degraded.slack: platform-alerts
```

## Best Practices

1. **Use App-of-Apps** - Centralize application management
2. **Separate Environments** - Use overlays or separate directories
3. **Enable Pruning** - Keep cluster in sync with Git
4. **Self-Healing** - Automatically revert drift
5. **Use Server-Side Apply** - For complex resources
6. **Configure Retries** - Handle transient failures
7. **Add Finalizers** - Ensure proper cleanup

