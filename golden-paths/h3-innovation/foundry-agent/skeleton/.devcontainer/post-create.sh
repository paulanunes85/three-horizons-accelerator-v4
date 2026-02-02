#!/bin/bash
# =============================================================================
# H3 Innovation - AI Foundry Agent - Post Create Script
# =============================================================================

set -e

echo "🤖 Setting up AI Foundry Agent: ${{ values.agentName }}..."

# -----------------------------------------------------------------------------
# Python environment
# -----------------------------------------------------------------------------
echo "🐍 Setting up Python environment for AI development..."

python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip

if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
fi

if [ -f "requirements-dev.txt" ]; then
    pip install -r requirements-dev.txt
fi

# Install common AI packages if not in requirements
pip install --quiet \
    openai \
    azure-identity \
    azure-ai-projects \
    semantic-kernel \
    promptflow \
    azure-ai-evaluation \
    python-dotenv

# -----------------------------------------------------------------------------
# Azure Developer CLI setup
# -----------------------------------------------------------------------------
if command -v azd &> /dev/null; then
    echo "🔧 Azure Developer CLI available"
    echo "   Run 'azd auth login' to authenticate"
fi

# -----------------------------------------------------------------------------
# Pre-commit hooks
# -----------------------------------------------------------------------------
if [ -f ".pre-commit-config.yaml" ]; then
    pip install pre-commit
    pre-commit install
fi

# -----------------------------------------------------------------------------
# Completion message
# -----------------------------------------------------------------------------
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo "✅ AI Foundry Agent environment ready!"
echo ""
echo "🔐 Authentication:"
echo "   az login                    # Azure CLI"
echo "   azd auth login              # Azure Developer CLI"
echo ""
echo "🚀 Quick start:"
echo "   1. Copy .env.example to .env and configure Azure OpenAI settings"
echo "   2. Run 'python src/agent.py' to test the agent locally"
echo "   3. Run 'pytest' for unit tests"
echo ""
echo "📦 Key packages installed:"
echo "   - openai, azure-ai-projects (Azure AI Foundry)"
echo "   - semantic-kernel (Agent orchestration)"
echo "   - promptflow (Prompt engineering)"
echo "   - azure-ai-evaluation (Agent evaluation)"
echo ""
echo "📚 Documentation:"
echo "   - Azure AI Foundry: https://ai.azure.com"
echo "   - Semantic Kernel: https://learn.microsoft.com/semantic-kernel"
echo "═══════════════════════════════════════════════════════════════════════"
