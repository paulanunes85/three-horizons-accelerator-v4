#!/bin/bash
# =============================================================================
# THREE HORIZONS - Post Create Script for Codespaces/Devcontainer
# =============================================================================

set -e

echo "🚀 Setting up development environment..."

# -----------------------------------------------------------------------------
# Install additional tools
# -----------------------------------------------------------------------------
echo "📦 Installing additional tools..."

# Terraform
if ! command -v terraform &> /dev/null; then
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    sudo apt-get update && sudo apt-get install -y terraform
fi

# kustomize
if ! command -v kustomize &> /dev/null; then
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
    sudo mv kustomize /usr/local/bin/
fi

# yq
if ! command -v yq &> /dev/null; then
    sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
    sudo chmod +x /usr/local/bin/yq
fi

# -----------------------------------------------------------------------------
# Language-specific setup
# -----------------------------------------------------------------------------

# Python
if [ -f "requirements.txt" ]; then
    echo "🐍 Setting up Python environment..."
    python -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    if [ -f "requirements-dev.txt" ]; then
        pip install -r requirements-dev.txt
    fi
fi

# Node.js
if [ -f "package.json" ]; then
    echo "📦 Setting up Node.js environment..."
    npm install
fi

# Go
if [ -f "go.mod" ]; then
    echo "🐹 Setting up Go environment..."
    go mod download
fi

# Java/Maven
if [ -f "pom.xml" ]; then
    echo "☕ Setting up Java environment..."
    mvn dependency:resolve
fi

# .NET
if [ -f "*.csproj" ] || [ -f "*.sln" ]; then
    echo "🟣 Setting up .NET environment..."
    dotnet restore
fi

# -----------------------------------------------------------------------------
# Pre-commit hooks
# -----------------------------------------------------------------------------
if [ -f ".pre-commit-config.yaml" ]; then
    echo "🔧 Installing pre-commit hooks..."
    pip install pre-commit
    pre-commit install
fi

# -----------------------------------------------------------------------------
# Git configuration
# -----------------------------------------------------------------------------
echo "🔧 Configuring Git..."
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global fetch.prune true

# -----------------------------------------------------------------------------
# Azure CLI login reminder
# -----------------------------------------------------------------------------
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo "🎉 Development environment ready!"
echo ""
echo "📝 Next steps:"
echo "   1. Run 'az login' to authenticate with Azure"
echo "   2. Run 'az account set -s <subscription>' to set your subscription"
echo "   3. Check README.md for project-specific instructions"
echo ""
echo "🔧 Available tools:"
echo "   - Azure CLI: $(az version --query '"azure-cli"' -o tsv 2>/dev/null || echo 'not logged in')"
echo "   - Terraform: $(terraform version -json | jq -r '.terraform_version' 2>/dev/null || echo 'not installed')"
echo "   - kubectl: $(kubectl version --client -o json | jq -r '.clientVersion.gitVersion' 2>/dev/null || echo 'not installed')"
echo "   - Helm: $(helm version --short 2>/dev/null || echo 'not installed')"
echo "   - ArgoCD: $(argocd version --client --short 2>/dev/null || echo 'not installed')"
echo "═══════════════════════════════════════════════════════════════════════"
