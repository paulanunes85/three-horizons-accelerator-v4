# Agent Validation Report

**Date:** February 2, 2026  
**Report Type:** Best Practices Compliance  
**Standards:** GitHub awesome-copilot + Microsoft Agent Framework

---

## Executive Summary

**Total Agents:** 23 workflow agents
- **H1 Foundation:** 8 agents
- **H2 Enhancement:** 5 agents  
- **H3 Innovation:** 4 agents
- **Cross-cutting:** 6 agents

**Compliance Status:** ⚠️ **REQUIRES UPDATES**

---

## Findings

### ✅ Strengths

1. **Consistent Structure**: All agents follow YAML frontmatter + markdown format
2. **Clear Workflows**: Mermaid diagrams for execution flows
3. **Detailed Issue Templates**: Comprehensive GitHub issue templates
4. **Command Examples**: Practical CLI commands for each phase
5. **Validation Criteria**: Clear acceptance criteria defined
6. **Agent Communication**: Human-readable status updates

### ⚠️ Critical Issues

#### 1. **Missing Skills Integration** (HIGH PRIORITY)

**Problem:** Agents reference MCP servers that don't exist and ignore actual skills in `.github/skills/`.

**Current State:**
```json
// ❌ Fictional MCP servers
{
  "mcpServers": {
    "terraform": {"command": "npx", "args": ["-y", "@anthropic/mcp-terraform"]},
    "argocd": {"command": "npx", "args": ["-y", "@anthropic/mcp-argocd"]},
    "helm": {"command": "npx", "args": ["-y", "@anthropic/mcp-helm"]}
  }
}
```

**Available Skills (ignored):**
- `terraform-cli` - Real Terraform operations
- `azure-cli` - Real Azure CLI commands
- `kubectl-cli` - Real Kubernetes operations
- `argocd-cli` - Real ArgoCD CLI commands
- `validation-scripts` - Reusable validation patterns

**Required Fix:** Replace fictional MCP servers with skill references

---

#### 2. **Dangerous Commands Without Confirmation** (SECURITY)

**Problem:** Agents execute destructive operations without explicit user consent.

**Examples Found:**
```bash
# ❌ No confirmation required
terraform apply tfplan
az resource delete --name ${RESOURCE}
kubectl delete namespace ${NS}
```

**Best Practice (from awesome-copilot):**
```markdown
**Explicit Consent Required for Actions**

- Never execute destructive or deployment-related commands without explicit user confirmation.
- For any tool usage that could modify state, first ask: "Should I proceed with [action]?"
- Default to "no action" when in doubt - wait for explicit "yes".
```

**Required Fix:** Add consent patterns to all destructive commands

---

#### 3. **No Agent Framework Integration** (ARCHITECTURE)

**Problem:** Agents don't follow Microsoft Agent Framework patterns for multi-agent workflows.

**Missing:**
- Agent state management
- Agent-to-agent communication patterns
- Workflow orchestration (fan-out/fan-in, condition, loop)
- Human-in-the-loop patterns
- Agent checkpointing for long-running tasks

**Best Practice (from microsoft/agent-framework):**
```python
# Should reference Agent Framework patterns
from agent_framework import ConditionalEdge, ParallelWorkflow
from agent_framework.openai import OpenAIChatClient

# Multi-agent orchestration
workflow = ParallelWorkflow(agents=[
    infrastructure_agent,
    security_agent,
    networking_agent
])
```

**Required Fix:** Add Agent Framework orchestration patterns

---

#### 4. **Skills Content Validation** (COMPLETENESS)

**Analysis of `.github/skills/`:**

| Skill | Status | Issues |
|-------|--------|--------|
| `terraform-cli` | ✅ Complete | Good reference guide |
| `azure-cli` | ✅ Complete | Comprehensive Azure CLI |
| `kubectl-cli` | ✅ Complete | K8s operations covered |
| `argocd-cli` | ✅ Complete | GitOps commands |
| `validation-scripts` | ⚠️ Partial | Missing compliance checks |

**Missing Skills:**
- `helm-cli` - Helm operations reference
- `github-cli` - GitHub API operations (gh commands)
- `docker-cli` - Container operations

**Required Fix:** Create missing skills, enhance validation-scripts

---

#### 5. **Terraform Best Practices Missing** (CODE QUALITY)

**Problem:** Agents don't reference Terraform best practices from awesome-copilot.

**Missing from agents:**
- Implicit dependencies over explicit `depends_on`
- Redundant `depends_on` detection
- Planning files handling (`.terraform-planning-files/`)
- Quality tools (tflint, terraform-docs, pre-commit hooks)
- State safety validation
- Security scanning (tfsec, checkov)

**Best Practice (from terraform-azure-implement.agent.md):**
```markdown
### Dependency and Resource Correctness Checks

- Prefer implicit dependencies over explicit `depends_on`
- **Redundant depends_on Detection**: Flag any `depends_on` where the depended resource is already referenced implicitly
- Use `grep_search` for "depends_on" and verify references
```

**Required Fix:** Add Terraform best practices section to infrastructure-related agents

---

#### 6. **AVM (Azure Verified Modules) Not Referenced** (AZURE)

**Problem:** Agents don't mention Azure Verified Modules for Terraform.

**Should Include:**
```markdown
### Azure Verified Modules (AVM)

- Use AVM modules where available: `Azure/avm-res-{service}-{resource}/azurerm`
- Pin module versions
- Enable telemetry: `enable_telemetry = var.enable_telemetry`
- Examples: `Azure/avm-res-keyvault-vault/azurerm`
```

**Required Fix:** Add AVM references to infrastructure, security, database, networking agents

---

## Detailed Recommendations by Agent

### H1 Foundation Agents

#### infrastructure-agent.md
**Issues:**
- ✅ Has naming module reference (good)
- ❌ Missing skills integration
- ❌ Missing explicit consent for `terraform apply`
- ❌ Missing AVM references
- ❌ Missing Terraform best practices (tflint, terraform-docs)

**Recommended Updates:**
```markdown
## Skills Integration

This agent leverages the following skills from `.github/skills/`:
- **terraform-cli**: For Terraform operations (`terraform init`, `plan`, `apply`)
- **azure-cli**: For Azure resource operations and validation
- **kubectl-cli**: For AKS cluster validation
- **validation-scripts**: For infrastructure validation patterns

## Terraform Best Practices

Before applying changes:
1. Run `terraform fmt -recursive`
2. Run `terraform validate`
3. Run `tfsec .` (security scan)
4. Review plan output carefully
5. **Explicit Consent**: Always ask "Should I proceed with terraform apply?"

### Azure Verified Modules (AVM)

Use AVM where available:
- AKS: `Azure/avm-res-containerservice-managedcluster/azurerm`
- ACR: `Azure/avm-res-containerregistry-registry/azurerm`
- Key Vault: `Azure/avm-res-keyvault-vault/azurerm`
```

#### security-agent.md
**Issues:**
- ❌ Missing Key Vault AVM reference
- ❌ Missing consent for RBAC assignments
- ❌ Missing validation of existing resources before creation

#### networking-agent.md
**Issues:**
- ❌ Missing VNet AVM reference
- ❌ No network security validation
- ❌ Missing private endpoint best practices

#### database-agent.md
**Issues:**
- ❌ Missing PostgreSQL Flexible Server AVM
- ❌ No backup validation
- ❌ Missing high availability configuration

#### container-registry-agent.md
**Issues:**
- ❌ Missing ACR AVM reference
- ❌ No georeplications validation  
- ❌ Missing image scanning setup

#### defender-cloud-agent.md
**Issues:**
- ✅ Good compliance standards
- ❌ Missing azapi provider patterns
- ❌ No validation of existing Defender setup

#### aro-platform-agent.md
**Issues:**
- ⚠️ ARO was removed from scope (should be archived or marked deprecated)
- ❌ References script-based deployment instead of Terraform

#### purview-governance-agent.md
**Issues:**
- ❌ Missing Purview best practices
- ❌ No data catalog validation
- ❌ Missing data lineage setup

---

### H2 Enhancement Agents

#### gitops-agent.md
**Issues:**
- ✅ Good ArgoCD workflow
- ❌ Missing argocd-cli skill reference
- ❌ Missing kubectl-cli skill reference
- ❌ No validation of existing ArgoCD installation
- ❌ Missing GitHub repo credentials validation

**Recommended Fix:**
```markdown
## Skills Integration

This agent leverages:
- **argocd-cli**: ArgoCD operations (from `.github/skills/argocd-cli/`)
- **kubectl-cli**: Kubernetes operations
- **helm-cli**: Helm chart management

## Pre-flight Validation

Before installation:
1. Check if ArgoCD already exists: `kubectl get namespace argocd`
2. Validate AKS cluster access: `kubectl cluster-info`
3. Verify GitHub repo access: `gh repo view ${ORG}/${REPO}`
4. **Explicit Consent**: Ask "Should I proceed with ArgoCD installation?"
```

#### rhdh-portal-agent.md
**Issues:**
- ❌ Missing RHDH v1.8 documentation references
- ❌ Missing GitHub App validation
- ❌ Missing Azure Workload Identity setup
- ❌ No PostgreSQL validation
- ❌ Missing reference to official RHDH docs in `RH-Developer-Hub-Documentation/`

**Critical:** Should reference platform agent's RHDH best practices

#### github-runners-agent.md
**Issues:**
- ❌ Missing GitHub Actions Runner Controller (ARC) patterns
- ❌ No runner registration validation
- ❌ Missing autoscaling configuration

#### observability-agent.md
**Issues:**
- ❌ Missing Prometheus Operator patterns
- ❌ No Grafana dashboard provisioning
- ❌ Missing Loki setup for logging

#### golden-paths-agent.md
**Issues:**
- ❌ Missing Backstage template validation
- ❌ No catalog refresh mechanism
- ❌ Missing software templates structure

---

### H3 Innovation Agents

#### ai-foundry-agent.md
**Issues:**
- ✅ Good AI Foundry structure
- ❌ Missing Azure AI SDK references
- ❌ No model deployment validation
- ❌ Missing RAG best practices
- ❌ No reference to AI Toolkit Agent Framework

**Recommended Addition:**
```markdown
## Microsoft Agent Framework Integration

For AI agent development, use Microsoft Agent Framework:

```python
from agent_framework.openai import OpenAIChatClient
from agent_framework import as_agent

# Create AI agent with tools
@as_agent
async def foundry_agent(context):
    client = OpenAIChatClient(
        endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
        model="gpt-4o"
    )
    # Agent logic
```

Reference: https://github.com/microsoft/agent-framework
```

#### mlops-pipeline-agent.md
**Issues:**
- ❌ Missing Azure ML best practices
- ❌ No pipeline validation
- ❌ Missing model registry setup

#### sre-agent-setup.md
**Issues:**
- ❌ Missing autonomous agent patterns
- ❌ No Agent Framework orchestration
- ❌ Missing human-in-the-loop patterns

---

### Cross-Cutting Agents

#### validation-agent.md
**Issues:**
- ✅ Comprehensive validation structure
- ❌ Missing validation-scripts skill reference
- ❌ No compliance framework validation
- ❌ Missing drift detection

**Should Add:**
```markdown
## Skills Integration

This agent uses:
- **validation-scripts**: Reusable validation patterns (from `.github/skills/validation-scripts/`)
- **terraform-cli**: State drift detection
- **azure-cli**: Resource validation
- **kubectl-cli**: Cluster health checks

## Validation Scripts Available

From `.github/skills/validation-scripts/`:
- `validate-azure-resources.sh` - Azure resource validation
- `validate-k8s-cluster.sh` - Kubernetes health checks
- `validate-terraform-state.sh` - Terraform state verification
- `detect-drift.sh` - Drift detection
- `compliance-check.sh` - Policy compliance
```

#### rollback-agent.md
**Issues:**
- ❌ Missing rollback strategy validation
- ❌ No backup verification before rollback
- ❌ Missing ArgoCD rollback patterns

#### cost-optimization-agent.md
**Issues:**
- ❌ Missing Azure Cost Management best practices
- ❌ No budget alerts setup
- ❌ Missing cost optimization recommendations

#### migration-agent.md
**Issues:**
- ❌ Missing migration validation
- ❌ No rollback strategy for failed migrations
- ❌ Missing data migration patterns

#### identity-federation-agent.md
**Issues:**
- ❌ Missing Workload Identity best practices
- ❌ No federated credential validation
- ❌ Missing OIDC issuer setup

#### github-app-agent.md
**Issues:**
- ❌ Missing GitHub App permissions validation
- ❌ No webhook secret validation
- ❌ Missing reference to RHDH GitHub integration

---

## Action Items

### Priority 1 (Critical - Security & Architecture)

1. **Add Explicit Consent Patterns** to all agents with destructive commands
   - Template: "Should I proceed with [terraform apply / az resource delete / kubectl delete]?"
   - Default to "no action" when in doubt

2. **Replace Fictional MCP Servers** with real skill references
   - Map to `.github/skills/` directory
   - Document skill usage patterns

3. **Create Missing Skills**
   - `helm-cli.md` - Helm operations
   - `github-cli.md` - GitHub API operations (gh commands)
   - Enhance `validation-scripts` with compliance checks

### Priority 2 (Best Practices)

4. **Add Terraform Best Practices Section** to infrastructure agents
   - Implicit dependencies preference
   - Redundant `depends_on` detection
   - Quality tools (tflint, terraform-docs, tfsec)
   - Pre-commit hooks

5. **Add AVM References** to Azure resource agents
   - Infrastructure, Security, Database, Networking agents
   - Pin versions, enable telemetry

6. **Add Agent Framework Patterns** to H3 agents
   - Multi-agent workflows
   - Agent orchestration (fan-out/fan-in)
   - Human-in-the-loop

### Priority 3 (Documentation)

7. **Update RHDH Agent** with official docs references
   - Link to `RH-Developer-Hub-Documentation/`
   - GitHub App setup per official guidelines
   - Azure Workload Identity configuration

8. **Add Validation Patterns** to all agents
   - Pre-flight checks
   - Post-deployment validation
   - Health checks

9. **Create Agent Integration Guide**
   - How agents call other agents
   - Workflow orchestration patterns
   - Dependency management

---

## Compliance Matrix

| Agent | Skills | Consent | Best Practices | AVM | Validation | Score |
|-------|--------|---------|---------------|-----|------------|-------|
| infrastructure-agent | ❌ | ❌ | ❌ | ❌ | ⚠️ | 20% |
| security-agent | ❌ | ❌ | ❌ | ❌ | ⚠️ | 20% |
| networking-agent | ❌ | ❌ | ❌ | ❌ | ❌ | 0% |
| database-agent | ❌ | ❌ | ❌ | ❌ | ❌ | 0% |
| gitops-agent | ❌ | ❌ | ⚠️ | N/A | ⚠️ | 40% |
| rhdh-portal-agent | ❌ | ❌ | ❌ | N/A | ❌ | 0% |
| ai-foundry-agent | ❌ | ❌ | ❌ | ❌ | ⚠️ | 20% |
| validation-agent | ❌ | N/A | ⚠️ | N/A | ⚠️ | 40% |
| **Average** | | | | | | **17.5%** |

**Legend:**
- ✅ Fully compliant
- ⚠️ Partially compliant
- ❌ Not compliant
- N/A: Not applicable

---

## Recommended Template Structure

Based on awesome-copilot and Agent Framework best practices:

```markdown
---
name: "{agent-name}"
version: "1.0.0"
horizon: "H1|H2|H3|cross-cutting"
status: "stable|beta|deprecated"
last_updated: "YYYY-MM-DD"
---

# {Agent Name}

## Skills Integration

This agent leverages the following skills from `.github/skills/`:
- **{skill-name}**: Description and usage
- **{skill-name}**: Description and usage

## Explicit Consent Required

**IMPORTANT**: This agent will request explicit user confirmation before:
- Running `terraform apply`
- Executing `az resource delete`
- Running `kubectl delete`
- Any destructive or state-modifying command

Default behavior: "no action" when in doubt.

## Best Practices

### Terraform
- Prefer implicit dependencies over explicit `depends_on`
- Run validation tools: `terraform fmt`, `terraform validate`, `tfsec`
- Use pre-commit hooks

### Azure
- Use Azure Verified Modules where available
- Pin module versions
- Enable telemetry

## Validation

### Pre-flight Checks
- [ ] Check 1
- [ ] Check 2

### Post-deployment Validation
- [ ] Validate 1
- [ ] Validate 2

## Agent Framework Integration

[For H3 agents] Use Microsoft Agent Framework patterns:
- Agent state management
- Multi-agent orchestration
- Human-in-the-loop

## Related Agents

| Agent | Relationship | Communication |
|-------|--------------|---------------|
| {agent} | Prerequisite | Via {method} |

```

---

## Next Steps

1. **Create Skills**:
   ```bash
   cd .github/skills
   mkdir helm-cli github-cli
   # Create SKILL.md for each
   ```

2. **Update Agents** (start with high-usage):
   - infrastructure-agent.md
   - gitops-agent.md
   - ai-foundry-agent.md
   - validation-agent.md

3. **Test Changes**:
   - Validate agent workflows with updated patterns
   - Test skill integrations
   - Verify consent prompts work

4. **Document**:
   - Update `agents/README.md` with new patterns
   - Create `agents/INTEGRATION_GUIDE.md`
   - Add examples to `agents/INDEX.md`

---

**Report Generated:** February 2, 2026  
**Validation Framework:** GitHub awesome-copilot + Microsoft Agent Framework  
**Compliance Score:** 17.5% (⚠️ REQUIRES IMMEDIATE ACTION)

