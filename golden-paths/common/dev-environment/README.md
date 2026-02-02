# Golden Paths - Development Environment Configuration

This directory contains reusable development environment configurations for GitHub Codespaces and Devbox. These configurations are automatically included in Golden Path template scaffolding.

## Available Configurations

### Generic (Universal)
- `.devcontainer/devcontainer.json` - Universal container with common tools
- `.devcontainer/post-create.sh` - Post-creation setup script
- `devbox.json` - Nix-based development environment

### Python
- `python/.devcontainer/devcontainer.json` - Python 3.12 with FastAPI tooling
- `python/devbox.json` - Python development with Poetry

### Node.js
- `nodejs/.devcontainer/devcontainer.json` - Node.js 20 with TypeScript tooling
- `nodejs/devbox.json` - Node.js development with pnpm

## Usage in Golden Path Templates

Templates can copy these configurations to the skeleton directory:

```yaml
# In template.yaml
- id: fetch-devenv
  name: Add Development Environment
  action: fetch:template
  input:
    url: ../../common/dev-environment/python
    targetPath: .
```

## GitHub Codespaces Features

All configurations include:
- GitHub Copilot & Copilot Chat
- Azure CLI & kubectl/helm
- Docker-in-Docker
- ArgoCD CLI
- Pre-commit hooks

## Devbox Features

Devbox provides:
- Reproducible Nix-based environments
- No Docker required
- Fast startup times
- Works on Mac, Linux, Windows (WSL)

### Quick Start with Devbox

```bash
# Install Devbox
curl -fsSL https://get.jetify.com/devbox | bash

# Start environment
devbox shell

# Run setup
devbox run setup

# Start development
devbox run dev
```

## Customization

To customize for a specific project:

1. Copy the appropriate language directory to your skeleton
2. Modify `devcontainer.json` for VS Code extensions and settings
3. Modify `devbox.json` for additional packages and scripts
4. Update `post-create.sh` for setup automation

## Port Conventions

| Port | Service |
|------|---------|
| 3000 | Node.js Express |
| 5432 | PostgreSQL |
| 6379 | Redis |
| 7071 | Azure Functions |
| 8000 | Python FastAPI |
| 8080 | Generic HTTP |
| 8888 | Jupyter |
| 9090 | Prometheus |
