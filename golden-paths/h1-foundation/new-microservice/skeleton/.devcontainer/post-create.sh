#!/bin/bash
# =============================================================================
# H1 Foundation - New Microservice - Post Create Script
# =============================================================================

set -e

echo "🚀 Setting up development environment for ${{ values.name }}..."

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
    [ -f "requirements-dev.txt" ] && pip install -r requirements-dev.txt
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

# Java
if [ -f "pom.xml" ]; then
    echo "☕ Setting up Java environment..."
    mvn dependency:resolve
fi

# .NET
if ls *.csproj 1>/dev/null 2>&1 || ls *.sln 1>/dev/null 2>&1; then
    echo "🟣 Setting up .NET environment..."
    dotnet restore
fi

# -----------------------------------------------------------------------------
# Pre-commit hooks
# -----------------------------------------------------------------------------
if [ -f ".pre-commit-config.yaml" ]; then
    pip install pre-commit 2>/dev/null || true
    pre-commit install
fi

# -----------------------------------------------------------------------------
# Completion message
# -----------------------------------------------------------------------------
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "✅ Development environment ready for ${{ values.name }}!"
echo ""
echo "Quick start:"
echo "  1. Review README.md for project documentation"
echo "  2. Run 'docker-compose up -d' for local services"
echo "  3. Start developing!"
echo ""
echo "Available ports:"
echo "  - 8080: Application"
echo "  - 5432: PostgreSQL"
echo "  - 6379: Redis"
echo "═══════════════════════════════════════════════════════════════"
