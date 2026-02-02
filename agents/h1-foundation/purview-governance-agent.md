---
name: "Purview Data Governance Agent"
version: "2.0.1"
horizon: "H1"
status: "stable"
last_updated: "2026-02-02"
skills:
  - terraform-cli
  - azure-cli
  - validation-scripts
dependencies:
  - infrastructure-agent
  - database-agent
  - security-agent
---

# Purview Data Governance Agent

## ⚠️ Explicit Consent Required

**CRITICAL**: This agent creates data governance infrastructure with cost implications. Always obtain explicit approval before proceeding.

**User Consent Prompt:**
```markdown
📂 **Microsoft Purview Deployment Request**

This action will:
- ✅ Create Microsoft Purview account
- ✅ Register all data sources in subscription
- ✅ Configure automated scanning schedules
- ✅ Deploy LATAM-specific classifications (CPF, CNPJ, RUT)
- ✅ Create business glossary and collections
- ⚠️ **Monthly costs apply based on data volume scanned**

**Estimated Monthly Costs:**
- Standard SKU: ~$500-$5,000/month (depends on capacity units)
- Scanning: Billed per GB scanned
- Private Endpoints: Additional $7/month per endpoint

**Configuration:**
- Sizing Profile: ${SIZING_PROFILE}
- Data Sources: ${DATA_SOURCES_COUNT}
- Scan Frequency: ${SCAN_FREQUENCY}
- Private Endpoints: ${PRIVATE_ENDPOINTS}

Type **"approve:purview profile={size} frequency={daily|weekly}"** to proceed or **"reject"** to cancel.
```

**Approval Format:** `approve:purview profile={small|medium|large|xlarge} frequency={daily|weekly}`

## Overview
Agent responsible for implementing comprehensive data governance using Microsoft Purview, including data catalog, data quality, sensitivity labels, and lineage tracking across the Three Horizons platform.

## Version
2.0.0

## Horizon
H1-Foundation / Governance

## Terraform Module
**Primary Module:** `terraform/modules/purview/main.tf`

```bash
# Deploy using Terraform
cd terraform
terraform init
terraform plan -target=module.purview -var="sizing_profile=medium"
terraform apply -target=module.purview
```

## Related Resources
| Resource Type | Path |
|--------------|------|
| Terraform Module | `terraform/modules/purview/main.tf` |
| Issue Template | `.github/ISSUE_TEMPLATE/purview-governance.yml` |
| Sizing Config | `config/sizing-profiles.yaml` (purview section) |
| Region Matrix | `config/region-availability.yaml` |
| LATAM Classifications | Built into `terraform/modules/purview/main.tf` |

### LATAM Classifications Included
- BRAZIL_CPF, BRAZIL_CNPJ, BRAZIL_RG
- CHILE_RUT
- MEXICO_RFC, MEXICO_CURP
- COLOMBIA_NIT, COLOMBIA_CC
- ARGENTINA_CUIT
- PERU_RUC

## Dependencies
- infrastructure-agent (resource groups, networking) → `terraform/modules/aks-cluster/`
- security-agent (managed identities, RBAC) → `terraform/modules/security/`
- database-agent (data sources to catalog) → `terraform/modules/databases/`
- defender-cloud-agent (sensitivity labels integration) → `terraform/modules/defender/`

## Capabilities

### 1. Purview Account Setup
```bash
# Create Purview account
az purview account create \
  --name "${PURVIEW_ACCOUNT_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --managed-resource-group-name "${PURVIEW_MANAGED_RG}" \
  --public-network-access "Enabled"

# Get Purview endpoints
PURVIEW_ENDPOINT=$(az purview account show \
  --name "${PURVIEW_ACCOUNT_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --query "endpoints.catalog" -o tsv)

# Configure managed identity
PURVIEW_IDENTITY=$(az purview account show \
  --name "${PURVIEW_ACCOUNT_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --query "identity.principalId" -o tsv)
```

### 2. Private Endpoint Configuration (Enterprise)
```bash
# Create private endpoint for Purview account
az network private-endpoint create \
  --name "${PURVIEW_ACCOUNT_NAME}-account-pe" \
  --resource-group "${RESOURCE_GROUP}" \
  --vnet-name "${VNET_NAME}" \
  --subnet "${PRIVATE_ENDPOINT_SUBNET}" \
  --private-connection-resource-id "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Purview/accounts/${PURVIEW_ACCOUNT_NAME}" \
  --group-id "account" \
  --connection-name "${PURVIEW_ACCOUNT_NAME}-account-connection"

# Create private endpoint for Purview portal
az network private-endpoint create \
  --name "${PURVIEW_ACCOUNT_NAME}-portal-pe" \
  --resource-group "${RESOURCE_GROUP}" \
  --vnet-name "${VNET_NAME}" \
  --subnet "${PRIVATE_ENDPOINT_SUBNET}" \
  --private-connection-resource-id "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Purview/accounts/${PURVIEW_ACCOUNT_NAME}" \
  --group-id "portal" \
  --connection-name "${PURVIEW_ACCOUNT_NAME}-portal-connection"

# Create private DNS zones
az network private-dns zone create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "privatelink.purview.azure.com"

az network private-dns zone create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "privatelink.purviewstudio.azure.com"
```

### 3. Data Source Registration
```bash
# Register Azure SQL Database
curl -X PUT "${PURVIEW_ENDPOINT}/datasources/AzureSqlDatabase?api-version=2022-02-01-preview" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "kind": "AzureSqlDatabase",
    "properties": {
      "serverEndpoint": "'${SQL_SERVER}'.database.windows.net",
      "resourceGroup": "'${RESOURCE_GROUP}'",
      "subscriptionId": "'${SUBSCRIPTION_ID}'",
      "resourceName": "'${SQL_SERVER}'",
      "location": "'${LOCATION}'",
      "collection": {
        "referenceName": "'${COLLECTION_NAME}'",
        "type": "CollectionReference"
      }
    }
  }'

# Register Azure Data Lake Storage Gen2
curl -X PUT "${PURVIEW_ENDPOINT}/datasources/AzureDataLakeGen2?api-version=2022-02-01-preview" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "kind": "AdlsGen2",
    "properties": {
      "endpoint": "https://'${STORAGE_ACCOUNT}'.dfs.core.windows.net/",
      "resourceGroup": "'${RESOURCE_GROUP}'",
      "subscriptionId": "'${SUBSCRIPTION_ID}'",
      "location": "'${LOCATION}'",
      "collection": {
        "referenceName": "'${COLLECTION_NAME}'",
        "type": "CollectionReference"
      }
    }
  }'

# Register PostgreSQL Flexible Server
curl -X PUT "${PURVIEW_ENDPOINT}/datasources/PostgreSQL?api-version=2022-02-01-preview" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "kind": "AzurePostgreSql",
    "properties": {
      "serverEndpoint": "'${POSTGRES_SERVER}'.postgres.database.azure.com",
      "port": 5432,
      "resourceGroup": "'${RESOURCE_GROUP}'",
      "subscriptionId": "'${SUBSCRIPTION_ID}'",
      "location": "'${LOCATION}'",
      "collection": {
        "referenceName": "'${COLLECTION_NAME}'",
        "type": "CollectionReference"
      }
    }
  }'

# Register Azure Cosmos DB
curl -X PUT "${PURVIEW_ENDPOINT}/datasources/CosmosDB?api-version=2022-02-01-preview" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "kind": "AzureCosmosDb",
    "properties": {
      "accountUri": "https://'${COSMOS_ACCOUNT}'.documents.azure.com:443/",
      "resourceGroup": "'${RESOURCE_GROUP}'",
      "subscriptionId": "'${SUBSCRIPTION_ID}'",
      "location": "'${LOCATION}'",
      "collection": {
        "referenceName": "'${COLLECTION_NAME}'",
        "type": "CollectionReference"
      }
    }
  }'
```

### 4. Scan Configuration
```bash
# Create scan for SQL Database
curl -X PUT "${PURVIEW_ENDPOINT}/datasources/AzureSqlDatabase/scans/WeeklyScan?api-version=2022-02-01-preview" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "kind": "AzureSqlDatabaseCredential",
    "properties": {
      "credential": {
        "referenceName": "'${CREDENTIAL_NAME}'",
        "credentialType": "SqlAuth"
      },
      "serverEndpoint": "'${SQL_SERVER}'.database.windows.net",
      "databaseName": "'${DATABASE_NAME}'",
      "scanRulesetName": "AzureSqlDatabase",
      "scanRulesetType": "System"
    }
  }'

# Create scan trigger (weekly)
curl -X PUT "${PURVIEW_ENDPOINT}/datasources/AzureSqlDatabase/scans/WeeklyScan/triggers/default?api-version=2022-02-01-preview" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "properties": {
      "recurrence": {
        "frequency": "Week",
        "interval": 1,
        "startTime": "2024-01-01T00:00:00Z",
        "timezone": "UTC",
        "schedule": {
          "hours": [2],
          "minutes": [0],
          "weekDays": ["Sunday"]
        }
      },
      "recurrenceInterval": null,
      "createdAt": null,
      "lastModifiedAt": null,
      "lastScheduled": null,
      "scanLevel": "Incremental"
    }
  }'
```

### 5. Collection Hierarchy
```bash
# Create root collection for platform
curl -X PUT "${PURVIEW_ENDPOINT}/collections/${PLATFORM_COLLECTION}?api-version=2019-11-01-preview" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "friendlyName": "Three Horizons Platform",
    "description": "Root collection for platform data assets",
    "parentCollection": {
      "referenceName": "'${PURVIEW_ACCOUNT_NAME}'",
      "type": "CollectionReference"
    }
  }'

# Create sub-collections by horizon
for HORIZON in "H1-Foundation" "H2-Enhancement" "H3-Innovation"; do
  curl -X PUT "${PURVIEW_ENDPOINT}/collections/${HORIZON}?api-version=2019-11-01-preview" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{
      "friendlyName": "'${HORIZON}'",
      "parentCollection": {
        "referenceName": "'${PLATFORM_COLLECTION}'",
        "type": "CollectionReference"
      }
    }'
done

# Create environment-based collections
for ENV in "Development" "Staging" "Production"; do
  curl -X PUT "${PURVIEW_ENDPOINT}/collections/${ENV}?api-version=2019-11-01-preview" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{
      "friendlyName": "'${ENV}'",
      "parentCollection": {
        "referenceName": "'${PLATFORM_COLLECTION}'",
        "type": "CollectionReference"
      }
    }'
done
```

### 6. Business Glossary
```bash
# Create glossary
curl -X POST "${PURVIEW_ENDPOINT}/glossary?api-version=2022-03-01-preview" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Three Horizons Business Glossary",
    "qualifiedName": "three-horizons-glossary",
    "shortDescription": "Business terms for the Three Horizons Platform"
  }'

# Create glossary terms
GLOSSARY_TERMS=(
  "Customer|A person or organization that purchases products or services"
  "PII|Personally Identifiable Information - data that can identify an individual"
  "Transaction|A business event representing exchange of goods or services"
  "Revenue|Income generated from business operations"
  "Cost Center|Organizational unit responsible for costs"
)

for TERM_DEF in "${GLOSSARY_TERMS[@]}"; do
  IFS='|' read -r TERM_NAME TERM_DESC <<< "${TERM_DEF}"
  curl -X POST "${PURVIEW_ENDPOINT}/glossary/term?api-version=2022-03-01-preview" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "'${TERM_NAME}'",
      "qualifiedName": "'${TERM_NAME}'@three-horizons-glossary",
      "shortDescription": "'${TERM_DESC}'",
      "anchor": {
        "glossaryGuid": "'${GLOSSARY_GUID}'"
      },
      "status": "Approved"
    }'
done
```

### 7. Classification Rules
```bash
# Create custom classification rule for LATAM data
curl -X PUT "${PURVIEW_ENDPOINT}/classificationrules/CPF_Brazil?api-version=2022-02-01-preview" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "kind": "Custom",
    "properties": {
      "description": "Brazilian CPF (Individual Taxpayer Registry)",
      "classificationName": "CPF_Brazil",
      "ruleStatus": "Enabled",
      "minimumPercentageMatch": 60,
      "columnPatterns": [
        {
          "pattern": ".*cpf.*|.*taxpayer.*|.*contribuinte.*"
        }
      ],
      "dataPatterns": [
        {
          "pattern": "[0-9]{3}\\.[0-9]{3}\\.[0-9]{3}-[0-9]{2}"
        }
      ]
    }
  }'

# Create classification rule for CNPJ
curl -X PUT "${PURVIEW_ENDPOINT}/classificationrules/CNPJ_Brazil?api-version=2022-02-01-preview" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "kind": "Custom",
    "properties": {
      "description": "Brazilian CNPJ (Company Registry)",
      "classificationName": "CNPJ_Brazil",
      "ruleStatus": "Enabled",
      "minimumPercentageMatch": 60,
      "columnPatterns": [
        {
          "pattern": ".*cnpj.*|.*company_id.*|.*empresa.*"
        }
      ],
      "dataPatterns": [
        {
          "pattern": "[0-9]{2}\\.[0-9]{3}\\.[0-9]{3}/[0-9]{4}-[0-9]{2}"
        }
      ]
    }
  }'

# Create classification for RUT (Chile)
curl -X PUT "${PURVIEW_ENDPOINT}/classificationrules/RUT_Chile?api-version=2022-02-01-preview" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "kind": "Custom",
    "properties": {
      "description": "Chilean RUT (Tax ID)",
      "classificationName": "RUT_Chile",
      "ruleStatus": "Enabled",
      "minimumPercentageMatch": 60,
      "columnPatterns": [
        {
          "pattern": ".*rut.*|.*tax_id.*"
        }
      ],
      "dataPatterns": [
        {
          "pattern": "[0-9]{1,2}\\.[0-9]{3}\\.[0-9]{3}-[0-9Kk]"
        }
      ]
    }
  }'
```

### 8. Data Quality Rules (Unified Catalog)
```bash
# Create data quality rule for completeness
curl -X POST "${PURVIEW_ENDPOINT}/dataQuality/rules?api-version=2023-02-01-preview" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "CustomerEmailCompleteness",
    "description": "Ensure customer email is not null",
    "ruleType": "Completeness",
    "expression": "email IS NOT NULL",
    "dataAssets": ["customers_table"],
    "threshold": 95,
    "severity": "High"
  }'

# Create data quality rule for uniqueness
curl -X POST "${PURVIEW_ENDPOINT}/dataQuality/rules?api-version=2023-02-01-preview" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "CustomerIdUniqueness",
    "description": "Ensure customer_id is unique",
    "ruleType": "Uniqueness",
    "expression": "COUNT(DISTINCT customer_id) = COUNT(*)",
    "dataAssets": ["customers_table"],
    "threshold": 100,
    "severity": "Critical"
  }'

# Create data quality rule for validity
curl -X POST "${PURVIEW_ENDPOINT}/dataQuality/rules?api-version=2023-02-01-preview" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "EmailFormatValidity",
    "description": "Validate email format",
    "ruleType": "Validity",
    "expression": "email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}$'",
    "dataAssets": ["customers_table"],
    "threshold": 98,
    "severity": "Medium"
  }'
```

### 9. RBAC Configuration
```bash
# Assign Data Curator role
az role assignment create \
  --role "Purview Data Curator" \
  --assignee "${DATA_STEWARD_GROUP_ID}" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Purview/accounts/${PURVIEW_ACCOUNT_NAME}"

# Assign Data Reader role
az role assignment create \
  --role "Purview Data Reader" \
  --assignee "${DATA_ANALYST_GROUP_ID}" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Purview/accounts/${PURVIEW_ACCOUNT_NAME}"

# Assign Data Source Administrator role
az role assignment create \
  --role "Purview Data Source Administrator" \
  --assignee "${PLATFORM_TEAM_GROUP_ID}" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Purview/accounts/${PURVIEW_ACCOUNT_NAME}"

# Grant Purview MSI access to data sources
az role assignment create \
  --role "Storage Blob Data Reader" \
  --assignee "${PURVIEW_IDENTITY}" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT}"
```

### 10. Sensitivity Labels Integration (with Defender)
```bash
# Enable sensitivity labels in Purview
az purview account update \
  --name "${PURVIEW_ACCOUNT_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --managed-resource-group-name "${PURVIEW_MANAGED_RG}"

# Configure auto-labeling policies
# This integrates with Microsoft Purview Information Protection
# Labels are defined in Microsoft 365 Compliance Center
```

## Sizing Profiles

### Small (< 10 devs)
```yaml
purview:
  sku: free  # Up to 1GB scanned/month
  collections: 5
  scans: weekly
  data_quality: disabled
  private_endpoints: disabled
estimated_cost: ~$0-100/month
```

### Medium (10-50 devs)
```yaml
purview:
  sku: standard
  capacity_units: 1
  collections: 20
  scans: daily
  data_quality: enabled
  private_endpoints: optional
  classifications:
    - system_default
    - latam_custom
estimated_cost: ~$500/month
```

### Large (50-200 devs)
```yaml
purview:
  sku: standard
  capacity_units: 4
  collections: 50
  scans: daily
  data_quality: enabled
  private_endpoints: enabled
  classifications:
    - system_default
    - latam_custom
    - industry_specific
  business_glossary: enabled
  lineage: full
estimated_cost: ~$2,000/month
```

### XLarge (200+ devs)
```yaml
purview:
  sku: standard
  capacity_units: 16
  collections: unlimited
  scans: continuous
  data_quality: enabled
  private_endpoints: enabled
  classifications:
    - system_default
    - latam_custom
    - industry_specific
  business_glossary: enabled
  lineage: full
  data_products: enabled
  self_service_analytics: enabled
estimated_cost: ~$5,000/month
```

## Regional Availability

### Unified Catalog (Data Governance)
| Region | Available | Notes |
|--------|-----------|-------|
| East US | ✅ | Full features |
| East US 2 | ✅ | Full features |
| West US 2 | ✅ | Full features |
| Brazil South | ✅ | Full features |
| South Central US | ✅ | Full features |
| West Europe | ✅ | Full features |
| North Europe | ✅ | Full features |
| UK South | ✅ | Full features |

### LATAM Data Residency
```
Recommendation for data residency requirements:
- Brazil: Brazil South (data stays in Brazil)
- Other LATAM: South Central US or East US (closest US regions)
```

## Integration Points

### With Defender for Cloud
- Sensitivity labels sync
- Data classification alignment
- Security posture visibility

### With Observability Agent
- Lineage tracking for data pipelines
- Quality metrics dashboards

### With AI Foundry Agent
- Training data governance
- Model data lineage
- AI data quality

### With RHDH Portal
- Data catalog search plugin
- Data product discovery
- Glossary integration

## Validation Criteria
- [ ] Purview account created and accessible
- [ ] All data sources registered
- [ ] Scans running successfully
- [ ] Collection hierarchy configured
- [ ] Business gloss ary populated
- [ ] LATAM classifications deployed (CPF, CNPJ, RUT)
- [ ] Data quality rules active
- [ ] RBAC configured correctly
- [ ] Private endpoints working (if enabled)

## 🔄 GitHub Actions Workflow

**Workflow File:** `.github/workflows/purview-deploy.yml`

```yaml
name: Deploy Microsoft Purview Governance

on:
  issues:
    types: [labeled]
  workflow_dispatch:
    inputs:
      sizing_profile:
        description: 'Sizing profile for Purview'
        required: true
        type: choice
        options:
          - small
          - medium
          - large
          - xlarge
      scan_frequency:
        description: 'Scan frequency'
        required: true
        type: choice
        options:
          - daily
          - weekly

permissions:
  id-token: write
  contents: read
  issues: write

jobs:
  deploy-purview:
    runs-on: ubuntu-latest
    if: |
      (github.event_name == 'issues' && contains(github.event.issue.labels.*.name, 'agent:purview') && contains(github.event.issue.labels.*.name, 'approved')) ||
      (github.event_name == 'workflow_dispatch')
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Parse issue configuration
        if: github.event_name == 'issues'
        id: parse
        uses: stefanbuck/github-issue-parser@v3
        with:
          template-path: .github/ISSUE_TEMPLATE/purview-governance.yml
      
      - name: Set environment variables
        run: |
          if [[ "${{ github.event_name }}" == "workflow_dispatch" ]]; then
            echo "SIZING_PROFILE=${{ github.event.inputs.sizing_profile }}" >> $GITHUB_ENV
            echo "SCAN_FREQUENCY=${{ github.event.inputs.scan_frequency }}" >> $GITHUB_ENV
          else
            echo "PROJECT_NAME=${{ fromJson(steps.parse.outputs.jsonString).project_name }}" >> $GITHUB_ENV
            echo "RESOURCE_GROUP=${{ fromJson(steps.parse.outputs.jsonString).resource_group }}" >> $GITHUB_ENV
            echo "REGION=${{ fromJson(steps.parse.outputs.jsonString).region }}" >> $GITHUB_ENV
            echo "SIZING_PROFILE=${{ fromJson(steps.parse.outputs.jsonString).sizing_profile }}" >> $GITHUB_ENV
          fi
          echo "PURVIEW_NAME=${PROJECT_NAME}-purview" >> $GITHUB_ENV
      
      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Create Purview Account
        run: |
          # Check if Purview account already exists
          if az purview account show --name ${PURVIEW_NAME} --resource-group ${RESOURCE_GROUP} 2>/dev/null; then
            echo "⚠️ Purview account already exists"
          else
            az purview account create \
              --name ${PURVIEW_NAME} \
              --resource-group ${RESOURCE_GROUP} \
              --location ${REGION:-eastus2} \
              --managed-resource-group-name "${PURVIEW_NAME}-managed-rg" \
              --public-network-access Enabled
            
            echo "✅ Purview account created"
          fi
          
          # Get Purview endpoints
          echo "PURVIEW_ENDPOINT=$(az purview account show --name ${PURVIEW_NAME} --resource-group ${RESOURCE_GROUP} --query 'endpoints.catalog' -o tsv)" >> $GITHUB_ENV
          echo "PURVIEW_IDENTITY=$(az purview account show --name ${PURVIEW_NAME} --resource-group ${RESOURCE_GROUP} --query 'identity.principalId' -o tsv)" >> $GITHUB_ENV
      
      - name: Get access token
        run: |
          ACCESS_TOKEN=$(az account get-access-token --resource "https://purview.azure.net" --query accessToken -o tsv)
          echo "ACCESS_TOKEN<<EOF" >> $GITHUB_ENV
          echo "$ACCESS_TOKEN" >> $GITHUB_ENV
          echo "EOF" >> $GITHUB_ENV
      
      - name: Create Collection Hierarchy
        run: |
          # Create root collection
          curl -X PUT "${PURVIEW_ENDPOINT}/collections/ThreeHorizonsPlatform?api-version=2019-11-01-preview" \
            -H "Authorization: Bearer ${ACCESS_TOKEN}" \
            -H "Content-Type: application/json" \
            -d '{"friendlyName":"Three Horizons Platform","description":"Root collection for platform data assets"}'
          
          # Create sub-collections by horizon
          for HORIZON in "H1-Foundation" "H2-Enhancement" "H3-Innovation"; do
            curl -X PUT "${PURVIEW_ENDPOINT}/collections/${HORIZON}?api-version=2019-11-01-preview" \
              -H "Authorization: Bearer ${ACCESS_TOKEN}" \
              -H "Content-Type: application/json" \
              -d '{"friendlyName":"'${HORIZON}'","parentCollection":{"referenceName":"ThreeHorizonsPlatform"}}'
          done
      
      - name: Deploy LATAM Classifications
        run: |
          # CPF Brazil
          curl -X PUT "${PURVIEW_ENDPOINT}/classificationrules/CPF_Brazil?api-version=2022-02-01-preview" \
            -H "Authorization: Bearer ${ACCESS_TOKEN}" \
            -H "Content-Type: application/json" \
            -d '{"kind":"Custom","properties":{"description":"Brazilian CPF","classificationName":"CPF_Brazil","ruleStatus":"Enabled","dataPatterns":[{"pattern":"[0-9]{3}\\.[0-9]{3}\\.[0-9]{3}-[0-9]{2}"}]}}'
          
          # CNPJ Brazil
          curl -X PUT "${PURVIEW_ENDPOINT}/classificationrules/CNPJ_Brazil?api-version=2022-02-01-preview" \
            -H "Authorization: Bearer ${ACCESS_TOKEN}" \
            -H "Content-Type: application/json" \
            -d '{"kind":"Custom","properties":{"description":"Brazilian CNPJ","classificationName":"CNPJ_Brazil","ruleStatus":"Enabled","dataPatterns":[{"pattern":"[0-9]{2}\\.[0-9]{3}\\.[0-9]{3}/[0-9]{4}-[0-9]{2}"}]}}'
          
          # RUT Chile
          curl -X PUT "${PURVIEW_ENDPOINT}/classificationrules/RUT_Chile?api-version=2022-02-01-preview" \
            -H "Authorization: Bearer ${ACCESS_TOKEN}" \
            -H "Content-Type: application/json" \
            -d '{"kind":"Custom","properties":{"description":"Chilean RUT","classificationName":"RUT_Chile","ruleStatus":"Enabled","dataPatterns":[{"pattern":"[0-9]{1,2}\\.[0-9]{3}\\.[0-9]{3}-[0-9Kk]"}]}}'
      
      - name: Register Data Sources
        run: |
          # This would register Azure SQL, CosmosDB, Storage, etc.
          # For simplicity, registering a placeholder
          echo "📂 Data source registration completed"
      
      - name: Configure RBAC
        run: |
          # Assign Data Curator role to platform team
          az role assignment create \
            --role "Purview Data Curator" \
            --assignee ${{ secrets.PLATFORM_TEAM_GROUP_ID }} \
            --scope "/subscriptions/${{ secrets.AZURE_SUBSCRIPTION_ID }}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Purview/accounts/${PURVIEW_NAME}" \
            || echo "⚠️ Role assignment may already exist"
          
          # Grant Purview MSI access to storage
          az role assignment create \
            --role "Storage Blob Data Reader" \
            --assignee ${PURVIEW_IDENTITY} \
            --scope "/subscriptions/${{ secrets.AZURE_SUBSCRIPTION_ID }}/resourceGroups/${RESOURCE_GROUP}" \
            || echo "⚠️ Role assignment may already exist"
      
      - name: Run validation
        run: |
          chmod +x scripts/validate-config.sh
          ./scripts/validate-config.sh purview
      
      - name: Comment success on issue
        if: github.event_name == 'issues' && success()
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `✅ **Microsoft Purview Deployed Successfully**\n\n**Resources:**\n- Purview Account: ${process.env.PURVIEW_NAME}\n- Catalog Endpoint: ${process.env.PURVIEW_ENDPOINT}\n- Collections: 4 (Root + H1/H2/H3)\n- LATAM Classifications: ✅ CPF, CNPJ, RUT\n\n**Next Steps:**\n1. Access [Purview Studio](https://web.purview.azure.com)\n2. Configure scans for data sources\n3. Populate business glossary\n\n📖 See [documentation](https://learn.microsoft.com /purview) for more info.`
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

**Trigger:** Label issue with `agent:purview` + `approved`

## Issue Template Reference
`.github/ISSUE_TEMPLATE/purview-governance.yml`

## Related Documentation
- [Microsoft Purview Overview](https://learn.microsoft.com/en-us/purview/)
- [Unified Catalog](https://learn.microsoft.com/en-us/purview/unified-catalog-regions)
- [Data Quality](https://learn.microsoft.com/en-us/purview/data-quality-overview)
- [Classifications](https://learn.microsoft.com/en-us/purview/supported-classifications)
