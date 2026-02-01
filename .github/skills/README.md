# Skills

> **Location**: `.github/skills/` following
> [awesome-copilot](https://github.com/github/awesome-copilot) best practices

Skills are self-contained folders with instructions and bundled resources
that teach AI agents specialized capabilities. Unlike custom instructions
(which define coding standards), skills enable task-specific workflows
that can include scripts, examples, templates, and reference data.

## Overview

| Skill | Description | Purpose |
|-------|-------------|---------|
| [azure-cli](./azure-cli/) | Azure CLI reference | Azure resource management |
| [terraform-cli](./terraform-cli/) | Terraform CLI reference | Infrastructure as Code |
| [kubectl-cli](./kubectl-cli/) | Kubernetes CLI reference | Cluster management |
| [argocd-cli](./argocd-cli/) | ArgoCD CLI reference | GitOps deployment |
| [validation-scripts](./validation-scripts/) | Validation patterns | Reusable scripts |

## Directory Structure

```text
.github/skills/
├── README.md                      # This file
├── azure-cli/
│   ├── SKILL.md                   # Azure CLI comprehensive reference
│   └── LICENSE.txt                # Apache 2.0 license
├── terraform-cli/
│   ├── SKILL.md                   # Terraform CLI reference
│   └── LICENSE.txt                # Apache 2.0 license
├── kubectl-cli/
│   ├── SKILL.md                   # Kubernetes CLI reference
│   └── LICENSE.txt                # Apache 2.0 license
├── argocd-cli/
│   ├── SKILL.md                   # ArgoCD CLI reference
│   └── LICENSE.txt                # Apache 2.0 license
└── validation-scripts/
    ├── SKILL.md                   # Validation patterns reference
    ├── LICENSE.txt                # Apache 2.0 license
    └── scripts/                   # Reusable validation scripts
        ├── validate-azure.sh
        ├── validate-kubernetes.sh
        └── validate-terraform.sh
```

## Progressive Loading Architecture

Skills use three-level loading for efficiency:

| Level            | What's Loaded              | When                             |
| ---------------- | -------------------------- | -------------------------------- |
| 1. Discovery     | `name` and `description`   | Always (lightweight metadata)    |
| 2. Instructions  | Full SKILL.md body         | When request matches description |
| 3. Resources     | Scripts, examples, docs    | Only when Copilot references     |

## Relationship with Agents

```text
┌─────────────────────────────────────────────────────────────┐
│                   .github/agents/                           │
│   (VS Code Chat Agents - *.agent.md files)                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ Uses
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        Skills                                │
│   (CLI references, command patterns, validation scripts)     │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ Complements
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      agents/ (root)                          │
│   (Detailed agent specifications for accelerator workflows)  │
└─────────────────────────────────────────────────────────────┘
```

- **`.github/agents/`**: VS Code Chat Agents (`*.agent.md`)
- **`.github/skills/`**: CLI references and reusable patterns (`SKILL.md`)
- **`agents/`**: Detailed accelerator workflow specifications

## Adding New Skills

Follow the awesome-copilot agent-skills.instructions.md:

1. Create a folder with the skill name (lowercase, hyphens)
2. Add `SKILL.md` with proper frontmatter:

   ```yaml
   ---
   name: skill-name
   description: >
     Detailed description of WHAT it does, WHEN to use it,
     and relevant KEYWORDS for discovery.
   license: Complete terms in LICENSE.txt
   ---
   ```

3. Add `LICENSE.txt` (Apache 2.0 recommended)
4. Include comprehensive documentation
5. Add bundled resources if needed:
   - `scripts/` - Executable automation
   - `references/` - Documentation for context
   - `assets/` - Static files used as-is
   - `templates/` - Starter code the AI modifies

## Agent to Skills Mapping

| Agent | Primary Skills |
|-------|----------------|
| architect | `terraform-cli`, `azure-cli`, `kubectl-cli` |
| devops | `azure-cli`, `terraform-cli`, `kubectl-cli`, `argocd-cli` |
| platform | `kubectl-cli`, `argocd-cli` |
| reviewer | `terraform-cli`, `kubectl-cli`, `validation-scripts` |
| security | `azure-cli` (compliance) |
| sre | `kubectl-cli`, `azure-cli`, `argocd-cli`, `validation-scripts` |

## Related Resources

- [Chat Agents](../agents/) - VS Code Copilot Chat Agents
- [Agent Specifications](../../agents/README.md) - Detailed workflow specs
- [MCP Servers Guide](../../agents/MCP_SERVERS_GUIDE.md) - MCP configuration
- [awesome-copilot](https://github.com/github/awesome-copilot) - Best practices
