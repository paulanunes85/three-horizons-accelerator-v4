---
name: rhdh-portal
description: Red Hat Developer Hub — installation, configuration, Golden Path registration, TechDocs, and portal management
---

## When to Use
- Install and configure RHDH on AKS/ARO
- Register Golden Path templates in the catalog
- Configure GitHub integration and OAuth
- Set up TechDocs publishing
- Manage catalog entities and plugins
- Onboard developer teams

## Prerequisites
- kubectl access to target cluster
- Helm 3.12+ installed
- Azure PostgreSQL deployed (via Terraform `databases` module)
- GitHub App configured (via `setup-github-app.sh`)
- Azure Storage Account for TechDocs (via Terraform `security` module)

## Installation & Configuration

### 1. Create Namespace and Secrets
```bash
# Create RHDH namespace
kubectl create namespace rhdh

# Create secrets (use values from Key Vault or env vars)
kubectl create secret generic rhdh-secrets \
  --namespace rhdh \
  --from-literal=GITHUB_APP_CLIENT_ID="${GITHUB_APP_CLIENT_ID}" \
  --from-literal=GITHUB_APP_CLIENT_SECRET="${GITHUB_APP_CLIENT_SECRET}" \
  --from-literal=GITHUB_APP_ID="${GITHUB_APP_ID}" \
  --from-literal=GITHUB_APP_PRIVATE_KEY="${GITHUB_APP_PRIVATE_KEY}" \
  --from-literal=GITHUB_WEBHOOK_SECRET="${GITHUB_WEBHOOK_SECRET}" \
  --from-literal=POSTGRESQL_HOST="${POSTGRESQL_HOST}" \
  --from-literal=POSTGRESQL_USER="${POSTGRESQL_USER}" \
  --from-literal=POSTGRESQL_PASSWORD="${POSTGRESQL_PASSWORD}" \
  --from-literal=ARGOCD_AUTH_TOKEN="${ARGOCD_AUTH_TOKEN}" \
  --from-literal=ARGOCD_ADMIN_PASSWORD="${ARGOCD_ADMIN_PASSWORD}" \
  --from-literal=GRAFANA_TOKEN="${GRAFANA_TOKEN}" \
  --from-literal=STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME}" \
  --from-literal=STORAGE_ACCOUNT_KEY="${STORAGE_ACCOUNT_KEY}" \
  --from-literal=K8S_SERVICE_ACCOUNT_TOKEN="${K8S_SA_TOKEN}"
```

### 2. Install RHDH via Helm
```bash
# Add Red Hat Helm repo
helm repo add openshift-helm-charts https://charts.openshift.io/
helm repo update

# Install RHDH with project config
helm install rhdh openshift-helm-charts/redhat-developer-hub \
  --namespace rhdh \
  --values platform/rhdh/values.yaml \
  --wait --timeout 15m

# Verify pods
kubectl get pods -n rhdh
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=backstage -n rhdh --timeout=600s
```

### 3. Verify Installation
```bash
# Check pod status
kubectl get pods -n rhdh

# Check logs for startup errors
kubectl logs -n rhdh -l app.kubernetes.io/name=backstage --tail=50

# Port forward for local access
kubectl port-forward -n rhdh svc/rhdh 7007:7007

# Verify API is responding
curl -s http://localhost:7007/api/catalog/entities | jq 'length'
```

## Golden Path Template Registration

### Register All Templates
```bash
# Register templates from GitHub (bulk)
for template_dir in golden-paths/h1-foundation/*/  golden-paths/h2-enhancement/*/ golden-paths/h3-innovation/*/; do
  template_name=$(basename "$template_dir")
  echo "Registering: $template_name"
  curl -X POST "https://developer.${DNS_ZONE_NAME}/api/catalog/locations" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${RHDH_TOKEN}" \
    -d "{\"type\":\"url\",\"target\":\"https://github.com/${GITHUB_ORG}/three-horizons-accelerator-v4/blob/main/${template_dir}template.yaml\"}"
done
```

### Register Individual Template
```bash
# Register a single template
curl -X POST "https://developer.${DNS_ZONE_NAME}/api/catalog/locations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${RHDH_TOKEN}" \
  -d '{"type":"url","target":"https://github.com/ORG/REPO/blob/main/golden-paths/h2-enhancement/microservice/template.yaml"}'
```

### Verify Templates
```bash
# List registered templates
curl -s "https://developer.${DNS_ZONE_NAME}/api/catalog/entities?filter=kind=Template" \
  -H "Authorization: Bearer ${RHDH_TOKEN}" | jq '.[].metadata.name'

# Count templates (expect 22)
curl -s "https://developer.${DNS_ZONE_NAME}/api/catalog/entities?filter=kind=Template" \
  -H "Authorization: Bearer ${RHDH_TOKEN}" | jq 'length'
```

## TechDocs Setup

### Configure TechDocs Publishing
```bash
# Ensure Azure Blob Storage container exists
az storage container create \
  --name techdocs \
  --account-name "${STORAGE_ACCOUNT_NAME}" \
  --auth-mode key

# Build and publish TechDocs for a component
npx @techdocs/cli generate --source-dir ./docs --output-dir ./site
npx @techdocs/cli publish \
  --publisher-type azureBlobStorage \
  --azureAccountName "${STORAGE_ACCOUNT_NAME}" \
  --azureAccountKey "${STORAGE_ACCOUNT_KEY}" \
  --entity default/component/my-service \
  --directory ./site
```

## Day-2 Operations

### Portal Health
```bash
# Check RHDH pods
kubectl get pods -n rhdh -l app.kubernetes.io/name=backstage

# Check portal logs
kubectl logs -n rhdh -l app.kubernetes.io/name=backstage --tail=100

# Port forward for local access
kubectl port-forward -n rhdh svc/rhdh 7007:7007
```

### Catalog Operations
```bash
# Register entity via API
curl -X POST "http://localhost:7007/api/catalog/locations" \
  -H "Content-Type: application/json" \
  -d '{"type":"url","target":"https://github.com/org/repo/blob/main/catalog-info.yaml"}'

# List entities
curl -s "http://localhost:7007/api/catalog/entities" | jq '.[].metadata.name'

# Refresh all entities
curl -X POST "http://localhost:7007/api/catalog/refresh"
```

### Team Onboarding
```bash
# Use the onboard-team script
.github/skills/rhdh-portal/scripts/onboard-team.sh --team-name <team> --github-org <org>
```

## Project Files Reference
- **Helm values:** `platform/rhdh/values.yaml`
- **Onboarding script:** `.github/skills/rhdh-portal/scripts/onboard-team.sh`
- **Golden Paths:** `golden-paths/` (22 templates across 3 horizons)
- **Terraform module:** `terraform/modules/rhdh/`

## Best Practices
1. Use GitHub App (not PAT) for integration
2. Configure OAuth for authentication
3. Use groups for access control
4. Enable TechDocs for all components
5. Register templates via catalog locations (not manual YAML)
6. Configure proper CORS settings
7. Use External Secrets for credential management

## Output Format
1. Command executed
2. Portal status
3. Entity count and status
4. Recommendations

## Integration with Agents
Used by: @platform, @devops
