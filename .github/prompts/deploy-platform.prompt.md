---
mode: agent
agent: deploy
description: Deploy the Three Horizons platform to an Azure environment
tools:
  - execute/runInTerminal
  - read/problems
---

# Deploy Platform

Deploy the Three Horizons Accelerator platform to Azure.

## Input
- **environment**: Target environment (dev, staging, prod)
- **horizon**: Which horizons to deploy (h1, h2, h3, all)

## Process

Three deployment options are available:

### Option A: Agent-Guided (Interactive)
I'll walk you through each step, running commands and validating results.

### Option B: Automated Script
```bash
./scripts/deploy-full.sh --environment {{ environment }} --horizon {{ horizon }}
```
Use `--dry-run` to preview first.

### Option C: Manual Guide
Follow the step-by-step instructions in `docs/guides/DEPLOYMENT_GUIDE.md`.

### Option D: Local Demo (No Azure Required)
```bash
make -C local up
```
Deploys the full platform locally on Docker Desktop + kind. No Azure subscription needed.

---

**Before deployment, I need to know:**
1. **Portal type:** Backstage (upstream, AKS only) or RHDH (enterprise, AKS or ARO)?
2. **Portal name:** What should the developer portal be called?

Which option would you prefer? If you're not sure, I recommend:
- **New to the platform** -> Option A (I'll guide you)
- **Familiar with the platform** -> Option B (fastest)
- **Want full control** -> Option C (manual)
- **No Azure / Demo** -> Option D (local)
