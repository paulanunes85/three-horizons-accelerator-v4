# MCP Servers for Three Horizons Accelerator

This directory documents the MCP (Model Context Protocol) servers used for Three Horizons deployment operations.

## Architecture: Hybrid Approach

Three Horizons uses a **hybrid approach**:

1. **VS Code MCPs** - For DevOps operations (PRs, pipelines, work items, wiki)
2. **Terminal Commands** - For infrastructure CLIs (az, terraform, kubectl, helm)

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Copilot Agent                      │
├─────────────────────────────────────────────────────────────┤
│  VS Code MCPs (API Operations)   │  Terminal (CLI Operations)│
│  ─────────────────────────────   │  ─────────────────────────│
│  • Azure DevOps (repos, PRs)     │  • az login/aks/acr       │
│  • Bicep schemas & AVM           │  • terraform plan/apply   │
│  • Firecrawl (web search)        │  • kubectl apply/get      │
│  • Apify (data extraction)       │  • helm install/upgrade   │
│                                  │  • argocd sync            │
└─────────────────────────────────────────────────────────────┘
```

## Available VS Code MCPs

### 1. Bicep / Azure Infrastructure

**Prefix:** `mcp_bicep_experim_*`

| Tool | Purpose |
|------|---------|
| `get_az_resource_type_schema` | Get Azure resource JSON schemas |
| `get_bicep_best_practices` | Bicep coding best practices |
| `list_avm_metadata` | List Azure Verified Modules |
| `list_az_resource_types_for_provider` | List resource types by provider |

**Usage:** H1 Foundation - Infrastructure schema validation

### 2. Azure DevOps

**Prefix:** `mcp_microsoft_azu_*`

#### Repositories
| Tool | Purpose |
|------|---------|
| `repo_list_repos_by_project` | List repositories |
| `repo_create_branch` | Create branches |
| `repo_create_pull_request` | Create PRs |
| `repo_list_pull_requests_by_repo_or_project` | List PRs |
| `repo_search_commits` | Search commit history |

#### Pipelines
| Tool | Purpose |
|------|---------|
| `pipelines_create_pipeline` | Create pipelines |
| `pipelines_run_pipeline` | Trigger pipeline runs |
| `pipelines_get_builds` | List builds |
| `pipelines_get_build_status` | Check build status |
| `pipelines_get_build_log` | Get build logs |

#### Work Items
| Tool | Purpose |
|------|---------|
| `wit_create_work_item` | Create tasks/bugs/stories |
| `wit_get_work_item` | Get work item details |
| `wit_update_work_item` | Update work items |
| `wit_my_work_items` | List my work items |
| `wit_add_child_work_items` | Add subtasks |

#### Wiki & Search
| Tool | Purpose |
|------|---------|
| `wiki_create_or_update_page` | Create/update docs |
| `wiki_get_page_content` | Read wiki pages |
| `search_code` | Search code in repos |
| `search_workitem` | Search work items |

### 3. Firecrawl (Web Search)

**Prefix:** `mcp_firecrawl_fir_*`

| Tool | Purpose |
|------|---------|
| `firecrawl_search` | Search the web |
| `firecrawl_scrape` | Scrape web pages |
| `firecrawl_crawl` | Crawl websites |
| `firecrawl_extract` | Extract structured data |
| `firecrawl_agent` | Autonomous web agent |

### 4. Apify

**Prefix:** `mcp_com_apify_api_*`

| Tool | Purpose |
|------|---------|
| `apify-slash-rag-web-browser` | RAG web browsing |
| `call-actor` | Run Apify actors |
| `search-actors` | Search actor store |

## Tool Discovery

Use `tool_search_tool_regex` to find available tools:

```json
// Find all Bicep tools
{ "pattern": "^mcp_bicep" }

// Find Azure DevOps repo tools
{ "pattern": "^mcp_microsoft_azu_repo" }

// Find pipeline tools
{ "pattern": "^mcp_microsoft_azu_pipelines" }

// Find work item tools
{ "pattern": "wit|work.?item" }

// Find any deployment tools
{ "pattern": "pipeline|build|deploy" }
```

## Horizon-Specific Usage

### H1 Foundation

```bash
# MCP Operations
- mcp_bicep_experim_get_az_resource_type_schema  # Validate resource configs
- mcp_bicep_experim_list_avm_metadata             # Find verified modules
- mcp_microsoft_azu_pipelines_run_pipeline        # Deploy infrastructure
- mcp_microsoft_azu_repo_create_pull_request      # Create infra PRs

# Terminal Operations
- az login --use-device-code
- terraform init && terraform plan
- terraform apply -auto-approve
- az aks get-credentials --resource-group rg --name aks
```

### H2 Enhancement

```bash
# MCP Operations
- mcp_microsoft_azu_pipelines_run_pipeline        # Deploy ArgoCD/RHDH
- mcp_microsoft_azu_wiki_create_or_update_page    # Document deployments
- mcp_microsoft_azu_wit_create_work_item          # Track tasks

# Terminal Operations
- helm upgrade --install argocd argo/argo-cd -n argocd
- kubectl apply -k deploy/kubernetes/base
- argocd app sync root-app
```

### H3 Innovation

```bash
# MCP Operations
- mcp_firecrawl_fir_firecrawl_search              # Research AI docs
- mcp_com_apify_api_apify-slash-rag-web-browser   # Gather AI data
- mcp_microsoft_azu_pipelines_run_pipeline        # Deploy AI Foundry

# Terminal Operations
- az cognitiveservices account create
- az ml workspace create
- kubectl apply -f agents/
```

## Configuration

The `mcp-config.json` file documents:

1. **vscodeMcpServers** - MCPs installed in VS Code
2. **serverGroups** - Which MCPs each horizon needs
3. **toolDiscovery** - Regex patterns to find tools
4. **terminalIntegration** - CLI commands for infrastructure

## Environment Variables

Required for full functionality:

```bash
# Azure DevOps
export AZURE_DEVOPS_ORG_URL="https://dev.azure.com/your-org"
export AZURE_DEVOPS_PAT="your-pat-token"

# Azure Infrastructure
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
export AZURE_TENANT_ID="your-tenant-id"

# Kubernetes
export KUBECONFIG="$HOME/.kube/config"
```

## Best Practices

1. **Use MCPs for DevOps** - PRs, work items, pipelines, wiki
2. **Use Terminal for Infra** - az, terraform, kubectl, helm
3. **Validate Between Horizons** - Run validation scripts before proceeding
4. **Document in Wiki** - Use wiki MCP to update deployment docs

## Related Documentation

- [MCP Servers Guide](../agents/MCP_SERVERS_GUIDE.md)
- [Deployment Sequence](../agents/DEPLOYMENT_SEQUENCE.md)
- [Architecture Guide](../docs/guides/ARCHITECTURE_GUIDE.md)
