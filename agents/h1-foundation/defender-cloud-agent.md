---
name: "Defender for Cloud Agent"
version: "2.0.0"
horizon: "H1"
status: "stable"
last_updated: "2026-02-02"
skills:
  - terraform-cli
  - azure-cli
  - validation-scripts
dependencies:
  - infrastructure-agent
  - security-agent
  - observability-agent
---

# Defender for Cloud Agent

## Overview
Agent responsible for implementing comprehensive cloud security posture management using Microsoft Defender for Cloud across the Three Horizons platform.

## Version
2.0.0

## Horizon
H1-Foundation / Security

## Terraform Module
**Primary Module:** `terraform/modules/defender/main.tf`

```bash
# Deploy using Terraform
cd terraform
terraform init
terraform plan -target=module.defender -var="sizing_profile=medium"
terraform apply -target=module.defender
```

## Related Resources
| Resource Type | Path |
|--------------|------|
| Terraform Module | `terraform/modules/defender/main.tf` |
| Issue Template | `.github/ISSUE_TEMPLATE/defender-cloud.yml` |
| Sizing Config | `config/sizing-profiles.yaml` (defender section) |
| Region Matrix | `config/region-availability.yaml` |
| Validation Script | `scripts/validate-config.sh` |

## Dependencies
- infrastructure-agent (resource groups, subscriptions) → `terraform/modules/aks-cluster/`
- networking-agent (private endpoints, NSGs) → `terraform/modules/networking/`
- security-agent (Key Vault, managed identities) → `terraform/modules/security/`

## ⚠️ Explicit Consent Required

**CRITICAL**: This agent performs subscription-wide security configurations with cost implications. Always obtain explicit approval before proceeding.

**User Consent Prompt:**
```markdown
🔐 **Defender for Cloud Configuration Request**

This action will:
- ✅ Enable Microsoft Defender plans (monthly costs apply)
- ✅ Configure security policies across subscription
- ✅ Enable continuous export to Log Analytics  
- ✅ Configure security contacts and notifications
- ⚠️ Estimated monthly cost: $100-$5,000 (based on sizing profile)

**Costs Breakdown:**
- CSPM: $0 (Free) or ~$5/resource (Standard)
- Containers: ~$7/vCore/month
- Servers: ~$15/server/month (P1), ~$30/server/month (P2)
- Databases: ~$15/server/month
- Storage: ~$10/million transactions/month

**Required Configuration:**
- Security Email: ${SECURITY_EMAIL}
- Security Phone: ${SECURITY_PHONE}
- Sizing Profile: [small/medium/large/xlarge]

Type **"approve:defender-cloud profile={sizing}"** to proceed or **"reject"** to cancel.
```

**Approval Format:** `approve:defender-cloud profile={small|medium|large|xlarge}`

## Capabilities

### 1. Defender Plans Enablement
```bash
# Enable Defender CSPM
az security pricing create \
  --name CloudPosture \
  --tier Standard

# Enable Defender for Containers
az security pricing create \
  --name Containers \
  --tier Standard \
  --extensions name=AgentlessDiscoveryForKubernetes isEnabled=True \
  --extensions name=ContainerRegistriesVulnerabilityAssessments isEnabled=True

# Enable Defender for Servers
az security pricing create \
  --name VirtualMachines \
  --tier Standard \
  --subplan P2

# Enable Defender for Databases
az security pricing create \
  --name SqlServers \
  --tier Standard

az security pricing create \
  --name OpenSourceRelationalDatabases \
  --tier Standard

az security pricing create \
  --name CosmosDbs \
  --tier Standard

# Enable Defender for Key Vault
az security pricing create \
  --name KeyVaults \
  --tier Standard

# Enable Defender for Storage
az security pricing create \
  --name StorageAccounts \
  --tier Standard \
  --subplan DefenderForStorageV2 \
  --extensions name=OnUploadMalwareScanning isEnabled=True \
  --extensions name=SensitiveDataDiscovery isEnabled=True

# Enable Defender for App Service
az security pricing create \
  --name AppServices \
  --tier Standard

# Enable Defender for DNS
az security pricing create \
  --name Dns \
  --tier Standard

# Enable Defender for Resource Manager
az security pricing create \
  --name Arm \
  --tier Standard

# Enable Defender for AI Services
az security pricing create \
  --name AI \
  --tier Standard
```

### 2. Security Contacts Configuration
```bash
# Configure security contacts
az security contact create \
  --name "default" \
  --alert-notifications "on" \
  --alerts-to-admins "on" \
  --email "${SECURITY_EMAIL}" \
  --phone "${SECURITY_PHONE}"

# Configure notification settings
az security auto-provisioning-setting update \
  --name "default" \
  --auto-provision "On"
```

### 3. Continuous Export Configuration
```bash
# Export to Log Analytics
az security automation create \
  --name "ExportToLogAnalytics" \
  --resource-group "${RESOURCE_GROUP}" \
  --scopes "[{\"description\":\"Subscription\",\"scopePath\":\"/subscriptions/${SUBSCRIPTION_ID}\"}]" \
  --sources "[{\"eventSource\":\"Alerts\"},{\"eventSource\":\"Recommendations\"},{\"eventSource\":\"SecureScores\"}]" \
  --actions "[{\"actionType\":\"LogAnalytics\",\"workspaceResourceId\":\"${LOG_ANALYTICS_ID}\"}]"

# Export to Event Hub (for SIEM integration)
az security automation create \
  --name "ExportToEventHub" \
  --resource-group "${RESOURCE_GROUP}" \
  --scopes "[{\"description\":\"Subscription\",\"scopePath\":\"/subscriptions/${SUBSCRIPTION_ID}\"}]" \
  --sources "[{\"eventSource\":\"Alerts\",\"ruleSets\":[{\"rules\":[{\"propertyJPath\":\"Severity\",\"propertyType\":\"String\",\"expectedValue\":\"High\",\"operator\":\"Equals\"}]}]}]" \
  --actions "[{\"actionType\":\"EventHub\",\"eventHubResourceId\":\"${EVENT_HUB_ID}\",\"connectionString\":\"${EVENT_HUB_CONNECTION}\"}]"
```

### 4. Regulatory Compliance Frameworks
```bash
# Add regulatory compliance standards
# Azure CIS 1.4.0
az security regulatory-compliance-standards list --query "[?name=='Azure-CIS-1.4.0']"

# Enable compliance assessments
az security assessment create \
  --name "SecurityCenterBuiltIn" \
  --status-code "Healthy"

# Configure compliance policies
az policy assignment create \
  --name "ASC-Default" \
  --policy-set-definition "1f3afdf9-d0c9-4c3d-847f-89da613e70a8" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}"
```

### 5. Attack Path Analysis (Defender CSPM)
```bash
# Enable attack path analysis
az security setting update \
  --name "MCAS" \
  --value "On"

# Configure cloud security graph
az security setting update \
  --name "Sentinel" \
  --value "On"
```

### 6. Container Security Configuration
```bash
# Enable container image scanning
az acr config vulnerability-scanning update \
  --registry "${ACR_NAME}" \
  --status "enabled"

# Configure admission control
cat <<EOF | kubectl apply -f -
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: defender-webhook
  labels:
    app.kubernetes.io/component: defender
webhooks:
- name: validation.defender.microsoft.com
  clientConfig:
    service:
      name: defender-webhook
      namespace: kube-system
      path: "/validate"
  rules:
  - apiGroups: [""]
    apiVersions: ["v1"]
    operations: ["CREATE", "UPDATE"]
    resources: ["pods"]
  admissionReviewVersions: ["v1"]
  sideEffects: None
EOF

# Install Defender DaemonSet
helm repo add azure-defender https://raw.githubusercontent.com/Azure/AKS-Defender/main/charts
helm install defender azure-defender/defender \
  --namespace kube-system \
  --set logAnalyticsWorkspaceResourceID="${LOG_ANALYTICS_ID}"
```

### 7. Kubernetes Security Policies
```bash
# Enable Azure Policy for Kubernetes
az aks enable-addons \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${AKS_CLUSTER}" \
  --addons azure-policy

# Apply Defender for Containers policies
az policy assignment create \
  --name "k8s-defender-policies" \
  --policy-set-definition "42b8ef37-b724-4e24-bbc8-7a7708edfe00" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}"
```

### 8. Just-In-Time VM Access
```bash
# Enable JIT for management VMs
az security jit-policy create \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --name "default" \
  --virtual-machines "[{\"id\":\"/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Compute/virtualMachines/${VM_NAME}\",\"ports\":[{\"number\":22,\"protocol\":\"TCP\",\"allowedSourceAddressPrefix\":\"*\",\"maxRequestAccessDuration\":\"PT3H\"}]}]"
```

### 9. Governance Rules
```bash
# Create governance rules for remediation
az rest --method PUT \
  --url "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.Security/governanceRules/HighSeverityRule?api-version=2022-01-01-preview" \
  --body '{
    "properties": {
      "displayName": "High Severity Remediation",
      "description": "Auto-assign high severity findings",
      "rulePriority": 100,
      "isGracePeriod": true,
      "governanceEmailNotification": {
        "disableManagerEmailNotification": false,
        "disableOwnerEmailNotification": false
      },
      "ownerSource": {
        "type": "ByTag",
        "value": "SecurityOwner"
      },
      "remediationTimeframe": "7.00:00:00",
      "isDisabled": false,
      "conditionSets": [{
        "conditions": [{
          "property": "$.AssessmentKey",
          "value": "all",
          "operator": "In"
        }]
      }]
    }
  }'
```

## Sizing Profiles

### Small (< 10 devs)
```yaml
defender_plans:
  cspm: free  # Basic CSPM only
  containers: standard
  servers: disabled
  databases: disabled
  key_vault: standard
  storage: standard
estimated_cost: ~$100/month
```

### Medium (10-50 devs)
```yaml
defender_plans:
  cspm: standard  # Full CSPM with attack paths
  containers: standard
  servers: P1
  databases: standard
  key_vault: standard
  storage: standard_with_scanning
continuous_export: log_analytics
estimated_cost: ~$500/month
```

### Large (50-200 devs)
```yaml
defender_plans:
  cspm: standard
  containers: standard
  servers: P2
  databases: standard
  key_vault: standard
  storage: standard_with_scanning
  app_services: standard
  dns: standard
  arm: standard
continuous_export: 
  - log_analytics
  - event_hub
governance_rules: enabled
estimated_cost: ~$2,000/month
```

### XLarge (200+ devs)
```yaml
defender_plans:
  cspm: standard
  containers: standard
  servers: P2
  databases: standard  # All DB types
  key_vault: standard
  storage: standard_with_scanning
  app_services: standard
  dns: standard
  arm: standard
  ai: standard
continuous_export:
  - log_analytics
  - event_hub
  - sentinel
governance_rules: enabled
regulatory_compliance:
  - azure_cis_1_4
  - nist_sp_800_53
  - pci_dss
  - iso_27001
  - sox
jit_access: enabled
estimated_cost: ~$5,000/month
```

## Regional Availability

### Full Feature Availability
| Region | CSPM | Containers | Servers | Databases | AI |
|--------|------|------------|---------|-----------|-----|
| East US | ✅ | ✅ | ✅ | ✅ | ✅ |
| East US 2 | ✅ | ✅ | ✅ | ✅ | ✅ |
| West US 2 | ✅ | ✅ | ✅ | ✅ | ✅ |
| Brazil South | ✅ | ✅ | ✅ | ✅ | ⚠️ Limited |
| South Central US | ✅ | ✅ | ✅ | ✅ | ✅ |
| West Europe | ✅ | ✅ | ✅ | ✅ | ✅ |
| North Europe | ✅ | ✅ | ✅ | ✅ | ✅ |

### LATAM Recommendation
```
Primary: Brazil South (all Defender plans available)
AI Workloads: East US 2 (Defender for AI fully available)
```

## Integration Points

### With Security Agent
- Shares Key Vault configuration
- Managed identity assignments
- Network security groups

### With Observability Agent
- Log Analytics workspace
- Alert forwarding
- Dashboard integration

### With AI Foundry Agent
- Defender for AI services
- Prompt injection protection
- Model security scanning

### With RHDH Portal
- Security dashboard plugin
- Compliance scorecard
- Vulnerability overview

## GitHub Actions Workflow

**Workflow File:** `.github/workflows/defender-cloud-deploy.yml`

```yaml
name: Deploy Defender for Cloud

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
  deploy-defender:
    runs-on: ubuntu-latest
    if: |
      (github.event_name == 'issues' && contains(github.event.issue.labels.*.name, 'agent:defender-cloud') && contains(github.event.issue.labels.*.name, 'approved')) ||
      (github.event_name == 'workflow_dispatch')
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Parse issue configuration
        if: github.event_name == 'issues'
        id: parse
        uses: stefanbuck/github-issue-parser@v3
        with:
          template-path: .github/ISSUE_TEMPLATE/defender-cloud.yml
      
      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Set environment variables
        run: |
          if [[ "${{ github.event_name }}" == "workflow_dispatch" ]]; then
            echo "SIZING_PROFILE=${{ github.event.inputs.sizing_profile }}" >> $GITHUB_ENV
          else
            echo "SIZING_PROFILE=${{ fromJson(steps.parse.outputs.jsonString).sizing_profile }}" >> $GITHUB_ENV
            echo "SECURITY_EMAIL=${{ fromJson(steps.parse.outputs.jsonString).security_email }}" >> $GITHUB_ENV
            echo "PROJECT_NAME=${{ fromJson(steps.parse.outputs.jsonString).project_name }}" >> $GITHUB_ENV
            echo "RESOURCE_GROUP=${{ fromJson(steps.parse.outputs.jsonString).resource_group }}" >> $GITHUB_ENV
          fi
      
      - name: Enable Defender CSPM
        run: |
          TIER=$([ "$SIZING_PROFILE" == "small" ] && echo "Free" || echo "Standard")
          az security pricing create \
            --name CloudPosture \
            --tier $TIER
      
      - name: Enable Defender for Containers
        run: |
          az security pricing create \
            --name Containers \
            --tier Standard \
            --extensions name=AgentlessDiscoveryForKubernetes isEnabled=True \
            --extensions name=ContainerRegistriesVulnerabilityAssessments isEnabled=True
      
      - name: Enable Defender for Servers
        run: |
          if [[ "$SIZING_PROFILE" != "small" ]]; then
            SUBPLAN=$([ "$SIZING_PROFILE" == "xlarge" ] && echo "P2" || echo "P1")
            az security pricing create \
              --name VirtualMachines \
              --tier Standard \
              --subplan $SUBPLAN
          fi
      
      - name: Enable Defender for Databases
        if: env.SIZING_PROFILE != 'small'
        run: |
          az security pricing create --name SqlServers --tier Standard
          az security pricing create --name OpenSourceRelationalDatabases --tier Standard
          az security pricing create --name CosmosDbs --tier Standard
      
      - name: Enable Defender for Storage
        run: |
          SCANNING=$([ "$SIZING_PROFILE" == "medium" ] || [ "$SIZING_PROFILE" == "large" ] || [ "$SIZING_PROFILE" == "xlarge" ] && echo "True" || echo "False")
          az security pricing create \
            --name StorageAccounts \
            --tier Standard \
            --subplan DefenderForStorageV2 \
            --extensions name=OnUploadMalwareScanning isEnabled=$SCANNING \
            --extensions name=SensitiveDataDiscovery isEnabled=$SCANNING
      
      - name: Configure security contacts
        if: github.event_name == 'issues'
        run: |
          az security contact create \
            --name "default" \
            --alert-notifications "on" \
            --alerts-to-admins "on" \
            --email "$SECURITY_EMAIL"
      
      - name: Enable continuous export to Log Analytics
        run: |
          LOG_ANALYTICS_ID=$(az monitor log-analytics workspace show \
            --resource-group $RESOURCE_GROUP \
            --workspace-name "${PROJECT_NAME}-logs" \
            --query id -o tsv)
          
          az security automation create \
            --name "ExportToLogAnalytics" \
            --resource-group $RESOURCE_GROUP \
            --scopes "[{\"description\":\"Subscription\",\"scopePath\":\"/subscriptions/${{ secrets.AZURE_SUBSCRIPTION_ID }}\"}]" \
            --sources "[{\"eventSource\":\"Alerts\"},{\"eventSource\":\"Recommendations\"},{\"eventSource\":\"SecureScores\"}]" \
            --actions "[{\"actionType\":\"LogAnalytics\",\"workspaceResourceId\":\"${LOG_ANALYTICS_ID}\"}]"
      
      - name: Validate Defender configuration
        run: |
          chmod +x scripts/validate-config.sh
          ./scripts/validate-config.sh defender
      
      - name: Comment success on issue
        if: github.event_name == 'issues' && success()
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `✅ **Defender for Cloud Configured Successfully**\n\n**Profile:** ${process.env.SIZING_PROFILE}\n\n**Plans Enabled:**\n- CSPM: ✅\n- Containers: ✅\n- Storage: ✅\n\n📊 Check [Azure Portal](https://portal.azure.com/#view/Microsoft_Azure_Security/SecurityMenuBlade/~/overview) for secure score.`
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

**Trigger:** Label issue with `agent:defender-cloud` + `approved`

## Validation Criteria
- [ ] All required Defender plans enabled
- [ ] Security contacts configured
- [ ] Continuous export to Log Analytics working
- [ ] Regulatory compliance assessments running
- [ ] Container scanning operational
- [ ] Secure score > 70%
- [ ] No high severity unaddressed findings > 7 days

## Issue Template Reference
`.github/ISSUE_TEMPLATE/defender-cloud.yml`

## Related Documentation
- [Defender for Cloud Overview](https://learn.microsoft.com/en-us/azure/defender-for-cloud/)
- [Defender for Containers](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-containers-introduction)
- [Defender CSPM](https://learn.microsoft.com/en-us/azure/defender-for-cloud/concept-cloud-security-posture-management)
- [Regulatory Compliance](https://learn.microsoft.com/en-us/azure/defender-for-cloud/regulatory-compliance-dashboard)
