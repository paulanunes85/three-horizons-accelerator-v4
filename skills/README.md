# Skills

Skills are self-contained knowledge modules that provide domain-specific context for GitHub Copilot. They complement the agent specifications by offering CLI references and reusable patterns.

## Overview

| Skill | Description | Purpose |
|-------|-------------|---------|
| [azure-cli](./azure-cli/) | Azure CLI reference | Azure resource management commands |
| [terraform-cli](./terraform-cli/) | Terraform CLI reference | Infrastructure as Code operations |
| [kubectl-cli](./kubectl-cli/) | Kubernetes CLI reference | Cluster management commands |
| [argocd-cli](./argocd-cli/) | ArgoCD CLI reference | GitOps deployment operations |
| [validation-scripts](./validation-scripts/) | Validation patterns | Reusable validation scripts |

## Directory Structure

```
skills/
├── README.md                      # This file
├── azure-cli/
│   └── SKILL.md                   # Azure CLI comprehensive reference
├── terraform-cli/
│   └── SKILL.md                   # Terraform CLI reference
├── kubectl-cli/
│   └── SKILL.md                   # Kubernetes CLI reference
├── argocd-cli/
│   └── SKILL.md                   # ArgoCD CLI reference
└── validation-scripts/
    ├── SKILL.md                   # Validation patterns reference
    └── scripts/                   # Reusable validation scripts
        ├── validate-azure.sh
        ├── validate-kubernetes.sh
        └── validate-terraform.sh
```

## Usage

Skills are automatically loaded by GitHub Copilot when relevant context is needed. They provide:

1. **CLI Reference**: Comprehensive command documentation
2. **Common Patterns**: Frequently used command combinations
3. **Best Practices**: Recommended approaches for operations
4. **Validation Scripts**: Reusable scripts for deployment validation

## Relationship with Agents

```
┌─────────────────────────────────────────────────────────────┐
│                        Agents                                │
│   (Orchestration specs with MCP servers, workflows,          │
│    dependencies, validation criteria)                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ Reference
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        Skills                                │
│   (CLI references, command patterns, validation scripts)     │
└─────────────────────────────────────────────────────────────┘
```

- **Agents**: Define WHAT to deploy and the execution workflow
- **Skills**: Provide HOW to execute specific CLI commands

## Adding New Skills

Follow the [awesome-copilot](https://github.com/github/awesome-copilot) format:

1. Create a folder with the skill name (lowercase, hyphens)
2. Add `SKILL.md` with frontmatter:
   ```yaml
   ---
   name: skill-name
   description: Brief description of the skill
   ---
   ```
3. Include comprehensive documentation
4. Add bundled assets if needed (scripts/, references/, assets/)

## Related Resources

- [Agents Documentation](../agents/README.md)
- [MCP Servers Guide](../agents/MCP_SERVERS_GUIDE.md)
- [Terraform Modules Reference](../agents/TERRAFORM_MODULES_REFERENCE.md)
