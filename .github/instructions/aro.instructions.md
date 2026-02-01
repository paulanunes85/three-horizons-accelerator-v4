---
description: 'Azure Red Hat OpenShift (ARO) standards, OpenShift patterns, operator installation, and RHDH/GitOps configuration for Three Horizons Accelerator'
applyTo: '**/aro/**/*.yaml,**/aro/**/*.yml,**/openshift/**/*.yaml,**/openshift/**/*.yml,**/scripts/deploy-aro.sh'
---

# Azure Red Hat OpenShift (ARO) Standards

## CLI Requirements

```bash
# Required CLIs
az --version        # Azure CLI with aro extension
oc version --client # OpenShift CLI
helm version        # Helm for charts
jq --version        # JSON processing
```

## ARO vs AKS Decision Matrix

| Criteria | Choose ARO | Choose AKS |
|----------|-----------|------------|
| Developer Portal | RHDH via Operator (native) | RHDH via Helm |
| GitOps | OpenShift GitOps Operator | ArgoCD Helm/manifest |
| Container Registry | Internal registry + ACR | ACR only |
| Ingress/Routes | OpenShift Routes (built-in) | NGINX/AGIC (addon) |
| Operators | OLM built-in | OLM addon or Helm |
| Service Mesh | OpenShift Service Mesh | Istio/OSM |
| Support | Red Hat + Microsoft | Microsoft |
| Compliance | FedRAMP, HIPAA ready | Varies |

## Cluster Provisioning

### Network Prerequisites

```bash
# VNet with dedicated subnets for ARO
az network vnet create \
  --resource-group ${RESOURCE_GROUP} \
  --name ${VNET_NAME} \
  --address-prefixes 10.0.0.0/16

# Master subnet (minimum /23)
az network vnet subnet create \
  --resource-group ${RESOURCE_GROUP} \
  --vnet-name ${VNET_NAME} \
  --name master-subnet \
  --address-prefixes 10.0.0.0/23 \
  --service-endpoints Microsoft.ContainerRegistry

# Worker subnet (minimum /23)
az network vnet subnet create \
  --resource-group ${RESOURCE_GROUP} \
  --vnet-name ${VNET_NAME} \
  --name worker-subnet \
  --address-prefixes 10.0.2.0/23 \
  --service-endpoints Microsoft.ContainerRegistry

# REQUIRED: Disable private link policies on master subnet
az network vnet subnet update \
  --resource-group ${RESOURCE_GROUP} \
  --vnet-name ${VNET_NAME} \
  --name master-subnet \
  --disable-private-link-service-network-policies true
```

### Resource Provider Registration

```bash
# Register required providers before cluster creation
az provider register -n Microsoft.RedHatOpenShift --wait
az provider register -n Microsoft.Compute --wait
az provider register -n Microsoft.Storage --wait
az provider register -n Microsoft.Authorization --wait
az provider register -n Microsoft.Network --wait
```

### Cluster Creation

```bash
# Create ARO cluster (30-45 minutes)
az aro create \
  --resource-group ${RESOURCE_GROUP} \
  --name ${CLUSTER_NAME} \
  --vnet ${VNET_NAME} \
  --master-subnet master-subnet \
  --worker-subnet worker-subnet \
  --worker-count 3 \
  --worker-vm-size Standard_D4s_v3 \
  --master-vm-size Standard_D8s_v3 \
  --pull-secret @pull-secret.txt \
  --domain ${CLUSTER_NAME}
```

## Sizing Profiles

| Profile | Workers | Worker VM | Master VM | Use Case |
|---------|---------|-----------|-----------|----------|
| small | 3 | Standard_D4s_v3 | Standard_D8s_v3 | Dev/Test |
| medium | 5 | Standard_D8s_v3 | Standard_D8s_v3 | Staging |
| large | 10 | Standard_D16s_v3 | Standard_D16s_v3 | Production |
| xlarge | 20 | Standard_D32s_v3 | Standard_D16s_v3 | Enterprise |

## Cluster Access

```bash
# Get API server URL
API_SERVER=$(az aro show \
  --resource-group ${RESOURCE_GROUP} \
  --name ${CLUSTER_NAME} \
  --query apiserverProfile.url -o tsv)

# Get kubeadmin password
KUBEADMIN_PASSWORD=$(az aro list-credentials \
  --resource-group ${RESOURCE_GROUP} \
  --name ${CLUSTER_NAME} \
  --query kubeadminPassword -o tsv)

# Login with oc CLI
oc login ${API_SERVER} \
  --username kubeadmin \
  --password ${KUBEADMIN_PASSWORD}

# Get console URL
CONSOLE_URL=$(az aro show \
  --resource-group ${RESOURCE_GROUP} \
  --name ${CLUSTER_NAME} \
  --query consoleProfile.url -o tsv)
```

## OAuth Configuration (Entra ID)

```yaml
# oauth-entra.yaml
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: EntraID
    mappingMethod: claim
    type: OpenID
    openID:
      clientID: ${ENTRA_APP_ID}
      clientSecret:
        name: entra-client-secret
      claims:
        preferredUsername:
        - preferred_username
        name:
        - name
        email:
        - email
        groups:
        - groups
      issuer: https://login.microsoftonline.com/${TENANT_ID}/v2.0
      extraScopes:
      - email
      - profile
```

```bash
# Create secret for OAuth
oc create secret generic entra-client-secret \
  --namespace openshift-config \
  --from-literal=clientSecret=${ENTRA_CLIENT_SECRET}

# Apply OAuth config
oc apply -f oauth-entra.yaml
```

## Operator Installation via OLM

### OpenShift GitOps Operator

```yaml
# gitops-operator.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-gitops-operator
  namespace: openshift-operators
spec:
  channel: latest
  installPlanApproval: Automatic
  name: openshift-gitops-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
```

```bash
# Apply and wait
oc apply -f gitops-operator.yaml
oc wait --for=condition=Ready pod \
  -l app.kubernetes.io/name=openshift-gitops-operator \
  -n openshift-operators --timeout=300s

# Get ArgoCD route
ARGOCD_ROUTE=$(oc get route openshift-gitops-server \
  -n openshift-gitops -o jsonpath='{.spec.host}')
```

### Red Hat Developer Hub (RHDH)

```yaml
# rhdh-operator.yaml - Install via OperatorHub
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: rhdh
  namespace: openshift-operators
spec:
  channel: fast  # or fast-1.8 for z-stream only updates
  installPlanApproval: Automatic
  name: rhdh
  source: redhat-operators
  sourceNamespace: openshift-marketplace
```

**Important**: Set `baseUrl` in app-config.yaml to match external URL of your Developer Hub instance.

```yaml
# Required ConfigMap with app-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-rhdh
  namespace: rhdh
data:
  app-config.yaml: |
    app:
      title: Red Hat Developer Hub
      baseUrl: https://developer-hub-rhdh.apps.${CLUSTER_DOMAIN}
    backend:
      baseUrl: https://developer-hub-rhdh.apps.${CLUSTER_DOMAIN}
      auth:
        externalAccess:
          - type: legacy
            options:
              subject: legacy-default-config
              secret: "${BACKEND_SECRET}"
---
# Required Secret for service-to-service authentication
apiVersion: v1
kind: Secret
metadata:
  name: my-rhdh-secrets
  namespace: rhdh
stringData:
  BACKEND_SECRET: "<base64-encoded-secret>"
```

```yaml
# rhdh-instance.yaml - Backstage Custom Resource (API v1alpha3)
apiVersion: rhdh.redhat.com/v1alpha3
kind: Backstage
metadata:
  name: developer-hub
  namespace: rhdh
spec:
  application:
    appConfig:
      mountPath: /opt/app-root/src
      configMaps:
        - name: app-config-rhdh
    extraEnvs:
      secrets:
        - name: my-rhdh-secrets
    replicas: 2
    route:
      enabled: true
      tls:
        termination: edge
  database:
    enableLocalDb: true  # Use external PostgreSQL in production
```

```bash
# Create namespace and apply
oc new-project rhdh
oc apply -f rhdh-operator.yaml
oc wait --for=condition=Established crd/backstages.rhdh.redhat.com --timeout=300s
oc apply -f rhdh-instance.yaml

# Get RHDH route
RHDH_ROUTE=$(oc get route developer-hub -n rhdh -o jsonpath='{.spec.host}')
```

### OpenShift Pipelines (Tekton)

```yaml
# pipelines-operator.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-pipelines-operator
  namespace: openshift-operators
spec:
  channel: latest
  installPlanApproval: Automatic
  name: openshift-pipelines-operator-rh
  source: redhat-operators
  sourceNamespace: openshift-marketplace
```

## OpenShift Routes Configuration

```yaml
# route-example.yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: ${APP_NAME}
  namespace: ${NAMESPACE}
  labels:
    app.kubernetes.io/name: ${APP_NAME}
    app.kubernetes.io/part-of: three-horizons
spec:
  host: ${APP_NAME}.apps.${CLUSTER_DOMAIN}
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
  to:
    kind: Service
    name: ${APP_NAME}
    weight: 100
```

## Security Context Constraints (SCC)

```bash
# List available SCCs
oc get scc

# Common SCCs for workloads
# - restricted-v2 (default, most secure)
# - nonroot-v2 (run as non-root)
# - anyuid (for legacy apps needing root)
# - privileged (avoid unless necessary)

# Grant SCC to service account
oc adm policy add-scc-to-user nonroot-v2 \
  -z ${SERVICE_ACCOUNT} -n ${NAMESPACE}
```

## ACR Integration

```bash
# Create pull secret for ACR
ACR_USERNAME=$(az acr credential show --name ${ACR_NAME} --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name ${ACR_NAME} --query "passwords[0].value" -o tsv)

oc create secret docker-registry acr-pull-secret \
  --docker-server=${ACR_NAME}.azurecr.io \
  --docker-username=${ACR_USERNAME} \
  --docker-password=${ACR_PASSWORD} \
  -n openshift-config

# Link to service accounts
oc secrets link default acr-pull-secret --for=pull -n ${NAMESPACE}
```

## RBAC for Entra ID Groups

```yaml
# cluster-admins.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: entra-cluster-admins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: ${ENTRA_ADMIN_GROUP_ID}
---
# developers-binding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: entra-developers
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: edit
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: ${ENTRA_DEVELOPERS_GROUP_ID}
```

## Validation Commands

```bash
# Cluster status
az aro show --resource-group ${RG} --name ${CLUSTER} --query provisioningState -o tsv

# Node status
oc get nodes -o wide

# Cluster operators
oc get clusteroperators

# Check GitOps operator
oc get subscription openshift-gitops-operator -n openshift-operators

# Check RHDH
oc get backstage -n rhdh
oc get routes -n rhdh

# Check OAuth configuration
oc get oauth cluster -o yaml

# Check pods in all namespaces
oc get pods --all-namespaces | grep -v Running | grep -v Completed
```

## Troubleshooting

```bash
# View cluster events
oc get events --sort-by='.lastTimestamp' -A

# Operator logs
oc logs -n openshift-operators deployment/openshift-gitops-operator

# RHDH logs
oc logs -n rhdh deployment/developer-hub-backstage

# Check failed pods
oc get pods -A | grep -E 'Error|CrashLoopBackOff|ImagePullBackOff'

# Debug node issues
oc adm node-logs ${NODE_NAME} -u kubelet

# API server audit logs
oc adm node-logs ${MASTER_NODE} --path=openshift-apiserver/
```

## Best Practices

1. **Use OLM for Operators**: Install operators via Operator Lifecycle Manager, not Helm
2. **OpenShift Routes over Ingress**: Use native Routes for better integration
3. **SCCs for Security**: Apply appropriate Security Context Constraints
4. **Entra ID for OAuth**: Configure OpenShift OAuth with Entra ID groups
5. **RHDH via Operator**: Deploy RHDH using the official Red Hat operator
6. **GitOps via Operator**: Use OpenShift GitOps operator (ArgoCD-based)
7. **Project Quotas**: Set ResourceQuotas and LimitRanges per namespace
8. **Image Streams**: Use OpenShift ImageStreams for image management
9. **Pull Secret Management**: Store Red Hat and ACR pull secrets properly
10. **Monitor with Built-in Tools**: Use OpenShift monitoring stack (Prometheus/Grafana)
